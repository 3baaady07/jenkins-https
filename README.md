# jenkins-https
https configured Jenkins container with Let's Encrypt SSL certificate.


## Usage
On Amazon Linux, run the following command:
```
curl https://raw.githubusercontent.com/3baaady07/jenkins-https/main/jenkins-https.sh > jenkins-https.sh
chmod 0755 jenkins-https.sh
```

Then, run the following command replacing values as needed:
```
./jenkins-https.sh "example@email.tld" "subdomain.mydomain.tld" "jenkins-vol"
```