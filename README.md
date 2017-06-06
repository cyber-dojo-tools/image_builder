# image_builder

Work in progress. Not live yet.

```
Checks dependency settings of image being rebuilt
Creates docker image
If docker image is for language+testFramework
   Verifies [ cyber-dojo start-point create name --git=REPO_URL ]
   Verifies start_point is red (using runner)
   Verifies red/amber/green code-files are red/amber/green (using runner)
   Verifies red/mber/green saved-outputs are red/amber/green
Notifies all dependent repos
```