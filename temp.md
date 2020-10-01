# Database Schema 
The Image below represents the schema of the Database

![Test Image 4](https://d2slcw3kip6qmk.cloudfront.net/marketing/pages/consideration-page/data-flow-diagram-software/Make-complicated-processes-easy-to-explain.png)



There are two applications to be deployed:

* React app - which is deployed to S3 using awscli on frontend machine
* Backend app - which is deployed to frontend machine with all the requirements

For each environment there is also a specific version to be deployed:

* For production environment - the `master` branch is deployed
* For beta environment - the `beta` branch is deployed
