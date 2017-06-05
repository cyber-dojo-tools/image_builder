# image_builder

Work in progress. Not live yet.

```
Check dependency settings of image being rebuilt
Create its docker image
if [ -d /start_point ]; then
   Verify [ cyber-dojo start-point create name --git=REPO_NAME ]
   Verify start_point is red (using runner)
   Verify red/amber/green visible-files are red/amber/green (runner)
   Verify reda/mber/green saved-output are red/amber/green
fi
Notify all dependent repos
```