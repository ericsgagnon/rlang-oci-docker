writeLines("
-------------------------------------------------------------
The files below can be used to configure your R environment.

Default user configuration files:
  ~/.config/R/.Renviron:  Environment Variables
  ~/.config/R/.Rprofile:  R commands (including this message)

If using a project, you can override these by placing 
files in the project directory:
  (project directory)/.Renviron
  (project directory)/.Rprofile

Note that if files exist in the project directory, 
the default ones will not be evaluated.
-------------------------------------------------------------
")

.user_package_dir <- "~/.local/share/R/4.0/lib"
.libPaths(c(.user_package_dir, .libPaths()))
rm(.user_package_dir) # cleanup 
# .libPaths() # check if needed
