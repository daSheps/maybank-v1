Task 1 
/
1.  Full environment should be able to setup by running terraform apply 
2.  vm from ASG is accesible via ssh from SSM host vm on public subnet. 


Task 2 
/k8s 
1.  Deployment sequence kubectl apply -f <filename> -n <desired-namespace>
        - config_secret.yaml
        - efs.yaml
        - deployment.yaml
        - network.yaml (after nginx controller is installed via helm )
2.  Nginx is configure with F5 nginx controller 
    reference :https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/
3.  Nginx's tls is not configured as no SSL cert is available, the cert can simply be added with 
    kubectl create secret tls --cert <ssl.crt> --key <key> # ssl.crt should be cat of cert , intermidiate cert , root cert 

