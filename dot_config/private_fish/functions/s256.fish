function s256 --description 'Generate hex-converted SHA256 string'
    read input --prompt-str="Input: "
    printf $input | sha256sum | cut -d ' ' -f 1 | xxd -r -p | base64
end

