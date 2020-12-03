writeLines("
-------------------------------------------------------------
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
R doesn't seem to inherit most environment variables 
from the host system: this work around allows you to 
manually capture them.
  envs           <- system2('env', stdout = T, stderr = T)
  envnames       <- sub('=.*', '', envs)
  envvars        <- sub('.*=', '', envs)
  names(envvars) <- envnames

another option is echo the environment variable 
(prefixed with $):
  os_path_envvar <- system2(
    command = 'echo',
    args = c('$PATH')
  )
-------------------------------------------------------------
")

.user_package_dir <- "~/.local/share/R/4.0/lib"
.libPaths(c(.user_package_dir, .libPaths()))
# .libPaths() # check if needed
rm(.user_package_dir) # cleanup 

# R doesn't seem to inherit most environment variables from
# the host system: this work around allows you to manually
# capture them.
# envs           <- system2("env", stdout = T, stderr = T)
# envnames       <- sub("=.*", "", envs)
# envvars        <- sub(".*=", "", envs)
# names(envvars) <- envnames

# another option is echo the environment variable (prefixed with $), eg:
# os_path_envvar <- system2(
#   command = "echo", 
#   args = c( "$PATH")
# )
