# image_builder

Work in progress. Not live yet.


```
Creates docker image
If start_point/ dir for language+testFramework
   Verifies [ cyber-dojo start-point create name --git=REPO_URL ]
   for runner_stateless
     Verifies start_point is red
     Verifies start_point tweaked amber is amber
     Verifies start_point tweaked green is green
   for runner_stateful
     Verifies start_point is red
     Verifies start_point tweaked amber is amber
     Verifies start_point tweaked green is green
Notifies all dependent repos
```