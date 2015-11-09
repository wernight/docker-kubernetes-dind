Docker-in-Docker container running Kubernetes and Docker Registry. It has `kubectl` and `docker-compose` commands pre-installed.

The main use case is to test (e.g. during continuous integration) the correct **deployment on Kubernetes of your project**. This can also be used to quickly test Kubernetes, in a single container, so it's easy to cleanup. It has the advantage of only requiring Docker to be installed on the host machine.

You do need to use a Docker Registry Mirror locally (and keep it running) so that for example Kubernetes images get cached.

Example of use case:

 1. Start Docker Registry Mirror (and keep it running even after your build is complete):

        $ docker run -d --name registry_mirror --restart=always \
              -p 127.0.0.1::5000 \
              -e STANDALONE=false \
              -e MIRROR_SOURCE=https://registry-1.docker.io \
              -e MIRROR_SOURCE_INDEX=https://index.docker.io \
              registry:2

 2. Start this image (in this example we mount also the path to our Kubenetes JSON/YAML):

        $ docker rm -f kubernetes_dind_1 || true
        $ docker run -d --name kubernetes_dind_1 --privileged \
              --link registry_mirror:registry_mirror \
              -p 127.0.0.1::5000 \
              -v $PWD/my-kubernetes-yaml:/code:ro \
              wernight/kubernetes-dind

 3. Push your images to the Docker Registry within the container (because Kubernetes need that):
 
        $ docker build -t my-image .
        $ docker tag -f my-image $(docker port kubernetes_dind_1 5000)/my-image
        $ docker push $(docker port kubernetes_dind_1 5000)/my-image
        $ docker rmi $(docker port kubernetes_dind_1 5000)/my-image
 
 4. Deploy on the Kubernetes running within the container (in this example it should start the image `localhost:5000/my-image`):

        $ docker exec kubernetes_dind_1 kubectl create -f /code/my-rc.yaml

 5. Run whatever system tests you want to check it works (use `--port` and make use of Kubernetes `externalIPs` to access your deployed website). You can also run them within the running containers (via `docker exec`).

 6. Clean-up by deleting the container:

        $ docker rm -f kubernetes_dind_1


Why Require a Registry Mirror?
------------------------------

Docker-in-Docker is great to clean-up everything, but it has the issue that it cannot use the outer Docker cache.

Solutions include:

  * Access Docker socket which makes sibling sockets (harder to clean-up and much harder to parallelize builds)
  * Use docker save/load (cannot be auto-built because that would require 250 MB under source control)
  * Push images to the local registry and use them (would require pushing 3 images at least)
  * Run a mirror registry (requires keeping a service running on the build machine)
  * Run an HTTP proxy with SSL cert injection since we use HTTPS (which is a complex hack)
  * See https://github.com/jpetazzo/dind/issues/65

So to avoid pushing 3 images each time and still not making full use of the cache, having a
Docker Registry Mirror seems the simplest and most effective alternative.
