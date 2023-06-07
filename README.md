# yuyatinnefeld.github.io
site: https://yuyatinnefeld.github.io


## How to use custom Domain for github pages?


### Update DNS Setup
- https://ap.www.namecheap.com/Domains/DomainControlPanel/xxxx

### Add Github IPs as A Record

```bash
A Record @ 185.199.108.153 5 min
A Record @ 185.199.109.153 5 min
A Record @ 185.199.110.153 5 min
A Record @ 185.199.111.153 5 min
```

### Create a CNAME file and write your domain address

/docs/CNAME

```bash
<<YOUR-DOMAIN>>
```