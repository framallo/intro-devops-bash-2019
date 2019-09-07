## Intro to DevOps - Bash - 2019

The purpose of this repository is to centralize the resources for the attendees of the "Intro to DevOps - Bash - 2019" for DensityLabs.

## Contents

```
|____.env.local.example
|____config
| |____puma
| | |____puma.example.rb
| |____nginx
| | |____default.example
|____README.md
|____devops_workshop_sept_2019.md
|____scripts
| |____deploy.example.sh
```
* `.env.local.example `- A example .env file that will hold the necessary environment variables for the sample app used in this workshop
* `config/puma/puma.example.rb` - The puma configuration in the sample app. Placed in this repo for demostration purposes.
* `config/nginx/default.example` - Sample configuration for nginx.
* `devops_workshop_sept_2019.md` - The guide for the workshop. While the slides will be available too, for some attendees it might be easier to follow a written document.
* `deploy.example.sh` - The bash script used in this workshop to deploy a sample app.

## Motivation

Originally I was just a Rails dev, but due to some circumstances I ended up playing the DevOps role for some projects in my company, knowing little to nothing about DevOps I looked through some blog posts and guide online and I honestly struggled quite a bit due to the different approaches but somehow managed to do a decent job (or so I'd like to believe).

Fast forward to a few months ago, certain event in my workplace made me realize how beneficial knowing how an app is setup and how it works in a remote server is. So a coworker made me the proposal to give this workshop and I accepted.

### Why bash?

While I admit I'm no DevOps guru, most of the time I'm just a dev. I worked with Mina, Capistrano and read a bit about Docker, right now I'm using Jenkins to automate most of our deployment related tasks but there was always some little thing that I had to use good ol' bash to get it done, like connecting a deployment process with an interactive CLI which Jenkins didn't like so I thought if I teach people to feel comfortable using bash then using other tools like Capistrano will be a piece of cake.
