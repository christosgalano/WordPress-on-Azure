# Post-Configuration Steps (also available in Wiki)

## Download database certificate in Kudo environment

* Go to <https://{{app-service-name}}.scm.azurewebsites.net/DebugConsole>

* Run the following:

```bash
cd /home/site/wwwroot && mkdir bin && cd bin
curl https://cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem -o DigiCertGlobalRootCA.crt.pem
```

## Import WordPress image to Azure Container Registry

* Login to vm-jumpbox through Bastion

* Run the following:

```bash
az login --identity
cr_name=""
az acr import -n $cr_name --source docker.io/library/wordpress:latest --image wordpress:latest
az acr repository list -n $cr_name
```

## Activate the Application Insights plug-in

* Login to WordPress

* Go to Plugins and activate the **Application Insights** plug-in

* Go to **Settings -> Application Insights** and set the Instrumentation Key

## Perform a Load Test

* Go to the Azure Load Testing resource that was created

* On the **Upload a JMeter script** option, click **Create**

* For the **Test Plan** provide the **tests/load_test_wordpress.jmx**

* In the **Monitoring** tab click **Add/Modify** and select the Application Insights resource that is connected to the WebApp

* On all the other tabs, provide the desired values

* Create and run the load test
