## Helper

Use this command to create new group first

```
sudo groupadd zookeeper -g 5000
```

Then, add system user (-r and --shell /bin/false) to it.

```
sudo useradd -r zookeeper --uid 5000 --shell /bin/false -g zookeeper
```

Check back user/group ID.

```
id zookeeper
```


## Software Based

|Software|  UID/GID |
|---|--|
| zookeeper  |  1000 |
| solr  |  5001 |
| mcowsgi  |  5901* |

## Project/Department based

|Project| Department | UID |
|---|---| --|
|  | NSL  | 2000 |
| GOSG |  | 2001 |
|  | ISL  | 2002 |
| MCO |  | 2003* |
| VLN | | 2004 |
| Mi-Flash | | 2099 |



## User based

| User | Department | UID | SSH Pub |
|--|--|--| -- |
| fairuz | NSL | 8888 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsyKvxnIBstbkPmPd+T2Nb3pEquKSVee9yDutnV3Udn fairuz@SHA256:a2fGi3VC6AuNlH/F+jhSvs9/+JXUylFpkVWmOa92fCQ`|
| azah | NSL | 8800 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOufMb1V4GtYUhGMjRb0oWWnQLnOMaZqUkIGqlTuaOsJ root@manis-portal` |
| amin | NSL | 8801 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvA/NkKIjS8kmsxe1wOpdCAU+J1I1az5VuaQSvDBA5U amin` |
| ricky | NSL | 8802 |
| nathan | NSL | 8803 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJfXXwlZu4wixblRnb5sKFJcqy6EYdls3lq2naqYZ91 nathan-key-20180117` |
| raif | NSL | 8804 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoihp6Dv4G8KN3WFkcbKdwAnVN9+iv7oJAprrhG9SiX raif@localhost.localdomain` |
| farihan | NSL | 8805 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXmVzPQVZ8k12cWinzDnCMzQ4rQhHvAI9BZyThvnVQt farihan@24:d6:be:4f:14:e0:e3:01:fc:fa:21:46:f2:94:62:a5` |
| samat | NSL | 8806 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVRyXqrCf6rmC5kpRXkbNeFJTT7I/1OxmPV0ibKYnPU samat@8a:74:87:d9:cf:9c:60:c0:44:c2:26:64:08:9a:aa:71` |
|anas | NSL | 8807 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7vLzFxFMsp2LtvOgeHvEcR0tBJnzAg0Sgn+mqHAuwP anas@ad:d2:53:a0:6e:af:1d:6b:5e:91:54:f3:55:08:8f:5c` |
|faisal | NSL | 8808 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKwaXPo6Jt3HcIGkHILwoEaOoxWa+3VtmpcLbaG+Vhv faisal@5a:13:fd:9e:86:4a:07:7c:58:0f:84:d6:7b:5b:0e:6f` |
|zaamzamir | NSL | 8809 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtqCxbAzXNFjgwHhxhNSg3J6X+tGq0aTrdpXXh6s7XU zam@bd:4e:26:26:b5:8f:a6:ad:59:a2:65:f2:bd:2e:f6:de` |
|firdaus | NSL | 8810 |
|shakir | CE/Sys | 8700 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIrhnHPWrf6aCRVgtVp8eoC/pgKLVvWZKZjo8hfUxWVF shakir@1d:58:dc:9f:ee:67:12:ad:90:59:22:a1:4d:4d:f6:08` |
|muzamiel.munir | CE/Sys | 8701| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIASthix9yxfVj4EeaCJ5b6JLlwIJSCP2ddJnJRP9DanZ` |
|nazeri | CE/DB | 8702| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWrwD6x362YpcGdrAAGMVwqz2n4lQkHTpHin+C6qNO/ nazeri` | 
|tester | PQRE | 8600| `ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1+iLCQxSFFIXdEcTkapHpKY2egZ23Y6cTAtK7x+/PcfFHZushZUI6C+QjdEhqh4kislZPW4eeWhS7tftMHzsD9/vWK9NpJeaEQMWBQtRsj4NVrG+b0nH71xceeJ0mGF8JtuL4E0hfWIUYSD5kjk+j3CITmoSzsqJvA5ZQWoEn62G1WAdl2UnRd30CYjI6VoW5NUPw2vJRcfDDXxRBH3Szrtf3pohPdhkopehBihlfVPSGDn2stg2Q0wVZ2a06bBBlBnXnlBUswS4WK5RJBioynKQybCB8UTk11CqMgl1bVzv81Yf5wSytT373CL/c2RKnrP4XnefXeUQ75hr5zEiWw== tester@mco` |
| dahlia | ISL | 8500| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0t3BTh08okW1tg93a59VMaQefLEZuRvr4IsIQrFab1 dahlia@SHA256:Dri2NHI2GW7G/zePpQr9o5iIJRwbLpMkubSe3bgUhi4` |
| kaywin | ISL | 8501| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYn2laN64U14iU27yi2X+hLgNYprL8WcBiIaWhVa5ag kaywin` |
| galoh | ISL | 8502| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9TsZI71OnTDKc+ndQvgrFdM9/RXRWwxgH9pHT6bpMD galoh` |
| misha | ISL | 8503| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRJ1xutAagfkKL9cYR/iP9hr6BQ+GGBv04hnfBASAWg misha` |
| izyani | ISL | 8504| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYV4nk+KLyvPiB82SP2E3oVWpk/L+dNgbG/v2/Pnu2f izyani` |
| jessie | ISL | 8506| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0KG3V3i1PebekGbuEBcAAxo669zbktQ/jE0fKsxHk4 jessie@SHA256:OQg3zBHOtbfzwiFc+UYxj5lEWOVz+4w63JEysJOR5iM` |
| azim | ISL | 8507| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdngSLWGme5eYQOWWqy3SsEk0X3ippBp1T6MbVjUvHg azim@SHA256:NfdktZBebFLGl7o/iCaETYBtpWJG4ZKjJ40AsNARPpg` |
| chpu | ISL | 8508| `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO//SH1p+Bjt5v3G+BWdslKxyS9XLm5boatcj9N0sOkG chpu` |
| amru | SDL | 8400 | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA45UwWFel8VnQnVC8NZ79PR/tswXATwX95rmTHFNOMy amru@8c:fa:b8:c4:d5:b0:9d:64:04:04:13:1f:0c:0b:f1:8d` |
| fadhly | SDL | 8401 |
