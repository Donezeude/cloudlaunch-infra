docker run -p 5001:5000 donezeude/first == runs my app on that localhost:5001

aws ec2 create-key-pair \
--key-name my-key-pair \
--key-type rsa \
--key-format pem \
--query "KeyMaterial" \
--output text > my-key-pair.pem == makes key pair