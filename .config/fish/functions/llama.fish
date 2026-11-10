#!/usr/bin/env fish
# Manage llama-server: switch models, control the systemd service.
#
# Subcommands:
#   llama ls                List discovered models in ~/models/*.gguf
#   llama use <alias>       Switch service to the given model (restarts it)
#   llama current           Show the active model's config
#   llama serve             Run llama-server in foreground (used by systemd)
#   llama start|stop|restart Control the systemd user service
#   llama logs [journal args]  Tail service logs (e.g. llama logs -n 50)
#   llama path              Print the active GGUF path
#   llama alias             Print the active alias
#
# To add a model the auto-discovery doesn't recognise, edit the
# __llama_aliases switch below; alias mapping overrides the file basename.

function llama --description "Manage llama-server model + service"
    set -l sub $argv[1]

    # --- helpers ---------------------------------------------------------

    function __llama_alias_for
        # $argv[1] = basename without .gguf; echo the friendly alias or '' if unknown
        set -l base "$argv[1]"
        switch "$base"
            case 'MiMo-V2.6-Distill-Qwen-9B-Q8_0'
                echo mimo-qwen9-q8
            case 'LFM2.5-24B-A2B-Q5_K_M'
                echo lfm25-24b-a2b
            case gemma-4-26B-A4B-it-qat-heretic-UD-Q4_K_XL
                echo gemma4-26b-a4b
            case 'Qwen3.8-27B-Humanlike-Chat-IQ4_XS'
                echo qwen35-27b-iq4
            case 'Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ2_XS-mtp'
                echo swift-iq2
            case '*'
                # fallback: lower-case the basename, drop version-ish bits
                string lower "$base" | string replace -ra '[-_][0-9].*$' ''
        end
    end

    function __llama_size_gb
        # $argv[1] = path; echo integer GiB (rounded)
        set -l bytes (stat -c '%s' "$argv[1]" 2>/dev/null)
        if test -z "$bytes"
            echo 0
            return
        end
        math "floor($bytes / 1024^3)"
    end

    function __llama_defaults
        # Pick sensible ctx/batch defaults based on alias (size-based fallback).
        # $argv[1] = alias, $argv[2] = path; echoes three lines: ctx batch ubatch
        set -l alias "$argv[1]"
        set -l path "$argv[2]"
        set -l gb (__llama_size_gb "$path")
        switch "$alias"
            case mimo-qwen9-q8
                echo 65536
                echo 2048
                echo 512
            case lfm25-24b-a2b
                # lfm2moe hybrid MoE (24B total / 2B active), native 131072 ctx;
                # only a few layers are attention so the KV cache stays small.
                # --fit on trims ctx if the 12 GB GPU can't hold it.
                echo 131072
                echo 2048
                echo 512
            case gemma4-26b-a4b
                echo 65536
                echo 1024
                echo 512
            case qwen35-27b-iq4
                echo 16384
                echo 512
                echo 128
            case swift-iq2
                echo 32768
                echo 512
                echo 256
            case '*'
                if test "$gb" -lt 12
                    echo 65536
                    echo 2048
                    echo 512
                else if test "$gb" -lt 18
                    echo 32768
                    echo 1024
                    echo 256
                else
                    echo 16384
                    echo 512
                    echo 128
                end
        end
    end

    function __llama_mmproj_for
        # $argv[1] = alias; echo the matching vision projector (mmproj) gguf
        # path, or nothing when the model has no vision component.
        set -l alias "$argv[1]"
        set -l path
        switch "$alias"
            case gemma4-26b-a4b
                set path "$HOME/models/mmproj-gemma-4-26B-A4B-it-qat-heretic-F16.gguf"
            case '*'
                return
        end
        if test -f "$path"
            echo "$path"
        end
    end

    function __llama_set_env
        # $argv[1] = alias, $argv[2] = path
        set -l alias "$argv[1]"
        set -l path "$argv[2]"
        set -l defaults (__llama_defaults "$alias" "$path")
        set -l mmproj (__llama_mmproj_for "$alias")
        systemctl --user set-environment \
            LLAMA_MODEL="$path" \
            LLAMA_ALIAS="$alias" \
            LLAMA_CTX_SIZE="$defaults[1]" \
            LLAMA_BATCH_SIZE="$defaults[2]" \
            LLAMA_UBATCH_SIZE="$defaults[3]" \
            LLAMA_MMPROJ="$mmproj"
    end

    function __llama_get_env
        # $argv[1] = variable name; echo its value from systemd user env
        set -l key "$argv[1]"
        for line in (systemctl --user show-environment)
            if string match -q "$key=*" "$line"
                string replace -r '^[^=]+=' '' "$line"
                return
            end
        end
    end

    function __llama_scan
        # emits TSV rows: alias\tpath\tsize_gb\tsize_human
        set -l models_dir "$HOME/models"
        if not test -d "$models_dir"
            return
        end
        for f in $models_dir/*.gguf
            set -l base (basename "$f" .gguf)
            if string match -q 'mmproj-*' "$base"
                continue
            end
            set -l alias (__llama_alias_for "$base")
            if test -z "$alias"
                continue
            end
            # -L follows symlinks so we report the real file size, not the
            # symlink target string length.
            set -l bytes (stat -L -c '%s' "$f" 2>/dev/null)
            if test -z "$bytes"
                set bytes (stat -c '%s' "$f")
            end
            set -l gb (math "floor($bytes / 1024^3)")
            set -l h (numfmt --to=iec --suffix=B "$bytes")
            printf '%s\t%s\t%s\t%s\n' "$alias" "$f" "$gb" "$h"
        end
    end

    # --- subcommands -----------------------------------------------------

    switch "$sub"
        case ls ''
            set -l rows (__llama_scan)
            if test -z "$rows"
                echo "No models in $HOME/models/*.gguf" >&2
                return 1
            end
            printf '%-22s %4s  %-8s  %s\n' ALIAS GiB SIZE PATH
            for r in $rows
                set -l parts (string split \t "$r")
                printf '%-22s %4s  %-8s  %s\n' "$parts[1]" "$parts[3]" "$parts[4]" "$parts[2]"
            end
        case use
            set -l target "$argv[2]"
            if test -z "$target"
                echo 'Usage: llama use <alias|partial>' >&2
                echo '  aliases:' >&2
                for r in (__llama_scan)
                    set -l p (string split \t "$r")
                    echo "    $p[1]" >&2
                end
                return 1
            end
            # exact alias match first
            set -l match
            for r in (__llama_scan)
                set -l parts (string split \t "$r")
                if test "$parts[1]" = "$target"
                    set match "$r"
                    break
                end
            end
            # substring fallback (case-insensitive)
            if test -z "$match"
                for r in (__llama_scan)
                    set -l parts (string split \t "$r")
                    if string match -qi "*$target*" "$parts[1]"; or string match -qi "*$target*" (basename "$parts[2]")
                        set match "$r"
                        break
                    end
                end
            end
            if test -z "$match"
                echo "No model matches '$target'." >&2
                return 1
            end
            set -l parts (string split \t "$match")
            __llama_set_env "$parts[1]" "$parts[2]"
            # Read back the values we just set for the status line.
            set -l new_ctx (__llama_get_env LLAMA_CTX_SIZE)
            set -l new_batch (__llama_get_env LLAMA_BATCH_SIZE)
            set -l new_ubatch (__llama_get_env LLAMA_UBATCH_SIZE)
            systemctl --user daemon-reload >/dev/null 2>&1
            systemctl --user restart llama-server.service
            sleep 2
            echo "Switched to: $parts[1]"
            echo "  $parts[2]"
            echo "  ctx=$new_ctx, batch=$new_batch, ubatch=$new_ubatch"
        case current
            set -l model (__llama_get_env LLAMA_MODEL)
            if test -z "$model"
                echo 'No model selected. Run: llama use <alias>' >&2
                return 1
            end
            systemctl --user show-environment | grep '^LLAMA_'
        case path
            __llama_get_env LLAMA_MODEL
        case alias
            __llama_get_env LLAMA_ALIAS
        case serve
            # Read config from systemd user env and exec llama-server in toolbox
            set -l model (__llama_get_env LLAMA_MODEL)
            set -l alias (__llama_get_env LLAMA_ALIAS)
            set -l ctx (__llama_get_env LLAMA_CTX_SIZE)
            set -l batch (__llama_get_env LLAMA_BATCH_SIZE)
            set -l ubatch (__llama_get_env LLAMA_UBATCH_SIZE)
            set -l mmproj (__llama_get_env LLAMA_MMPROJ)
            if test -z "$model"
                echo 'No model selected. Run: llama use <alias>' >&2
                return 1
            end
            # Defaults for unset values
            if test -z "$ctx"
                set ctx 65536
            end
            if test -z "$batch"
                set batch 2048
            end
            if test -z "$ubatch"
                set ubatch 512
            end
            if test "$alias" = swift-iq2
                # 27B IQ2 on the 12 GB RTX 5070: weights (~8.2 GB) + f16 KV +
                # recurrent state (~0.75 GB) do not fit alongside the desktop,
                # and this fork's turbo3/turbo2 KV types dequantise on the CPU
                # (GPU idles, ~0.7 t/s). A hard -ngl 999 with turbo KV OOMs.
                # Fix: standard q4_0 KV (GPU-accelerated, ~0.56 B/elem) sized so
                # every layer stays on the GPU with -ngl 999. ctx comes from
                # __llama_defaults (32768). MTP spec-decode is omitted: its
                # draft context needs a second recurrent-state buffer and OOMs.
                exec /usr/bin/toolbox run -c fedora-toolbox-41-cuda \
                    /var/home/somme/clone/atomic-llama-cpp-turboquant/build/bin/llama-server \
                    -m "$model" \
                    --alias "$alias" \
                    --host 0.0.0.0 \
                    --port 8001 \
                    --reasoning-budget 4096 \
                    --reasoning-budget-message "思考限界に到達。適切な最終回答をします" \
                    --verbosity 3 \
                    -ngl 999 \
                    --repeat-penalty 1.00 \
                    --top-p 0.95 \
                    --top-k 20 \
                    --temp 0.6 \
                    --load-mode none \
                    -c "$ctx" \
                    --chat-template-kwargs '{"reasoning_effort":"low"}' \
                    -np 1 \
                    -fa on \
                    -b 512 \
                    -ub 256 \
                    -ctk q4_0 \
                    -ctv q4_0
            end
            set -l fit_args --fit on --fit-target 512
            if test "$alias" = gemma4-26b-a4b
                set -a fit_args --fit-ctx 131072
            end
            # Attach the vision projector when the selected model has one;
            # an empty list expands to nothing.
            set -l mmproj_args
            if test -n "$mmproj"
                set mmproj_args --mmproj "$mmproj"
            end
            set -l sampling_args --temp 1.0 --top-p 0.95 --top-k 64 --repeat-penalty 1.0
            if test "$alias" = lfm25-24b-a2b
                # LFM2.5 recommends these in its GGUF metadata: temp 0.1,
                # top-k 50, repeat-penalty 1.05 (top-p left at the default).
                set sampling_args --temp 0.1 --top-p 0.95 --top-k 50 --repeat-penalty 1.05
            end
            exec /usr/bin/toolbox run -c fedora-toolbox-41-cuda \
                /var/home/somme/clone/llama.cpp/build/bin/llama-server \
                -m "$model" \
                --alias "$alias" \
                $mmproj_args \
                --host 0.0.0.0 \
                --port 8001 \
                --ctx-size "$ctx" \
                --batch-size "$batch" \
                --ubatch-size "$ubatch" \
                $fit_args \
                -ctk q8_0 -ctv q8_0 \
                --flash-attn on \
                --threads 10 --threads-batch 12 \
                --parallel 1 --no-warmup --jinja \
                $sampling_args
        case start
            systemctl --user start llama-server.service
        case stop
            systemctl --user stop llama-server.service
        case restart
            systemctl --user restart llama-server.service
        case logs
            set -l args $argv[2..-1]
            if set -q args[1]
                journalctl --user -u llama-server.service $args
            else
                journalctl --user -u llama-server.service -f
            end
        case help -h --help
            echo 'Usage: llama {ls|use <alias>|current|path|alias|serve|start|stop|restart|logs}'
        case '*'
            echo "Unknown subcommand: $sub" >&2
            echo 'Usage: llama {ls|use <alias>|current|path|alias|serve|start|stop|restart|logs}' >&2
            return 1
    end
end
