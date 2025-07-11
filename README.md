# Tool Manager (tm)

**Tool Manager (tm)** is a lightweight framework for managing collections of Bash shell tools and plugins.  
Think of it as a *package manager for your shell scripts*: it installs, updates, and isolates command-line tools so you can focus on using them—not setting them up. 

It is not limited to running just bash scripts, the goal is to provide script support for as many different languages as possible (typscript, java, kotlin, c#, js, go, perl...). The tool-manager would provide as much of the environment, isolation,
dependency management as possible, in an easy way, so your focus can be on just writing scripts.

---

## Why Use Tool Manager?
Developers often accumulate many shell scripts or small CLI tools over time. 

We basically got bored trying to remember where our scripts were, managing dependencies, having to choose a particular language, configuration, hooking in to our bashrc, deciding how to back them up, share them etc. The focus shoud be on what we want the scripts to do, not the fluffing around. We also wanted to be able to choose the language best suited for the problem at hand, and be able to change our mind later. Also, as time went on, our small
bash script started to grow, and we wanted a way to cater for that growth.

Tool Manager helps by addressing several common pain points:

- **Centralized Installation**  
  Instead of manually cloning repositories or copying scripts, then dumping them somewhere randomly, you can instead install new tools with a single command.
  For example, running `tm-plugin-install <vendor>/<tool-name>` will fetch and set up a tool plugin for you, in a consistent location.
  This saves time and ensures a consistent install process for any machine.


- **Easy Enable/Disable**  
  Tool Manager lets you enable or disable plugins on demand. This means your shell isn’t cluttered with
  commands you don’t need – you can turn tools on only when needed and keep others disabled.
  The system **manages plugins** and can quickly toggle them without manual PATH juggling.


- **Isolated Environments**  
  To avoid conflicts between tools, Tool Manager can (now or in the future) run plugins in isolated contexts (like separate containers or virtual environments).
  This isolation ensures that one tool’s requirements won’t break another’s environment.


- **Multiple Contexts (Prefixes)**  
  If you need the same tool in different configurations (for example, a personal vs. work setup),
  you can install it under distinct prefixes. Tool Manager supports prefixing plugin names (e.g. `my:git-tools` vs `work:git-tools`)
  so that each has its own config but shares the same code base.
  This solves the issue of **conflicting configurations** by cleanly separating contexts.


- **Dependency Management**  
  A major headache with scripts is managing their dependencies (like Python packages or other binaries). Tool Manager automates this.
  You can declare dependencies in your script (using special `@require` comments), and Tool Manager will automatically set up a Python virtual environment and install those packages when the tool is run.
  This means no more “it works on my machine” problems due to missing libraries – the required packages are pulled in for you.


- **Discoverability and Updates**  
  Tool Manager keeps track of what plugins are available, installed, or enabled. You can list all available plugins (from its plugin registry or known sources) or see which ones you’ve installed with simple commands.
  This makes it easy to discover new tools and ensure your toolkit is up to date. It also streamlines updates (you could update a plugin by reinstalling or pulling latest changes in its directory, under Tool Manager’s control).


- **Imports**
  In the bash world, there isn't a consistent way to import other people libraries (or your own from various places), over and
  above the humble 'source' command. While this works, you still have to deal with path issues depending on where your script was called from, or end up with a bunch of annoying boilerplate at the top of each script file. There is also the issue or importing a file multiple times if your scripts get complicated and start referencing each other. The tool-manager solves this via:

```bash
  #!/usr/bin/env env-tm-bash
  _include_once @tm/lib.args.sh .my.common.sh @some-vendor/some-plugin/lib.foo.sh
````

   or
```bash
  _include @tm/lib.args.sh .my.common.sh @some-vendor/some-plugin/lib.foo.sh
```

or

```bash
  _include_once @tm/lib.args.sh
  _include_once @some-vendor/some-plugin/lib.foo.sh
  _include_once .my.common.sh  
```  

  This will source the shared '@tm/lib.args.sh' library (@tm is the toolmanager namespace), the '.my.common.sh' (which is relative to your current script), and a thirdparty plugins exported lib '@some-vendor/some-plugin/lib.foo.sh'. The current
  script directory issues are automatically taken care of.


  You can also include your own plugins exported lib (in folder <plugin-home>/lib-shared) using a '@this'

```bash
  _include_once @this/lib.something.sh
``` 

  This then better supports forking a repo and publishing under a different name

  There are a number of libs that are provided out of the box. Use '@tm/lib....'

  - lib.args.sh     - make it easy to parse commands line args, along with validation, help message generation etc
  - lib.logs.sh     - provide logging for scripts
  - lib.cfg.sh      - provide script configutation management
  - lib.util.sh     - common bash enhancements (probably should be called lib.lang.sh)
  - lib.validate.sh - argument validation support 
  - lib.file.*.sh   - read/write various file formats
  - and more...

By solving these issues, Tool Manager makes it much easier to maintain a robust set of shell tools, share them with others, and keep your environment clean and consistent.

---

## Key Features
Tool Manager provides a number of features that deliver the above benefits:

- **Unified Command Prefix**  
  All Tool Manager commands and managed tools start with the prefix `tm-`. This means you can type `tm-` and press tab to see available actions, making discovery intuitive.
  For example, `tm-help-commands` will list all tool commands you have installed.
  This consistent naming prevents naming collisions with other system commands and groups plugin actions together for convenience.


- **Plugin Life-Cycle Commands**  
  It offers an array of commands to manage plugin *life cycle*. You can install plugins from remote sources (GitHub by default) using `tm-plugin-install`,
  edit plugin files (`tm-plugin-edit` opens the installation directory), reload plugins (`tm-reload` regenerates the shell wrappers for tools), and configure plugins (`tm-plugin-cfg` opens their config).
  These commands abstract the fiddly steps of managing script files and shell initialization. For instance, after adding a new script to a plugin, running tm-reload will regenerate wrapper scripts so that the tool is immediately available in your PATH with the correct environment.


- **Flexible Installation Sources**  
  Pull plugins from the public registry, GitHub (`user/repo`), or any Git URL.
  If the tool you want isn’t in the default registry, that’s fine – Tool Manager will try to fetch it from GitHub by convention, or you can point it to any Git repository URL.
  The tool infers the plugin name and vendor from the URL, so you aren’t limited to a predefined list of plugins. This flexibility means you can install any script repository as a plugin, whether it’s one of the officially known plugins or your own custom repo.


- **Automatic Dependency Provisioning**  
  Tool Manager can automatically handle dependencies for scripts, particularly Python ones. By adding lines like `# @require:python 3.12` or `# @require:pip <package>` in the script, you signal Tool Manager to set up the appropriate Python version and pip packages in an isolated virtual environment.
  The next time you run the script, it will launch with those dependencies available, without you manually creating a virtualenv or installing packages globally. Support for other runtimes (Node, Deno, Java, etc.) is in the works, extending this convenience to tools written in other languages.


- **Plugin Registry and Listings**  
  Tool Manager comes with a plugin registry (a catalog of known tool plugins) which it uses for installations and listings.
  By running commands like `tm-plugin-ls --available` or `tm-plugin-ls --installed`, you get a quick overview of what tools you can add or what you already have. This feature helps you discover new productivity tools and manage existing ones without digging through folders.

All these features work together so that adding a new bash tool or sharing your custom script with teammates becomes a frictionless process. In short, Tool Manager abstracts away the setup chores and lets you focus on using or developing the tools.

---

## Example Use Cases

To illustrate how Tool Manager can be used in practice, here are a few scenarios:

- **Installing a Toolkit from GitHub**  
  Imagine you want to use a set of helpful Git-related scripts someone published. If those scripts are packaged as a Tool Manager plugin (for example, a plugin named **git-tools** by user *codemucker*),
  you can install them by running `tm-plugin-install codemucker/git-tools`. This single command will retrieve the plugin from GitHub and make all its commands available in your shell.
  Without Tool Manager, you might have had to manually clone the repo, move scripts into your PATH, and deal with dependencies.
  With Tool Manager, it’s one-step and you’re ready to go. If you later decide to tweak these tools or use your own fork, you could use `tm-plugin-edit codemucker/git-tools` to jump to its installation directory, or install your fork by pointing `tm-plugin-install` at your repository URL.


- **Managing Personal vs Work Scripts**  
  Let’s say you have a script called `git-each` that you use at work, but with different settings for personal projects.
  Using Tool Manager’s prefix feature, you can install two instances of the same plugin – one as `my:codemucker/git-tools`
  for personal use and another as `work:codemucker/git-tools` for work.
  This will create two sets of commands (e.g., `my-git-each` and `work-git-each`), each with its own configuration files, even though they share the same underlying code.
  It cleanly separates contexts so you don’t mix up configurations. At any time, you can enable or disable one set if you only want to use the other, ensuring no interference between your personal and work environments.


- **Automatic Environment Setup for a Script**  
  Suppose you write a Bash tool that internally uses Python (perhaps to leverage a library like `tkinter` for a GUI or some data processing).
  Distributing this tool to others can be tricky if they need certain Python packages.
  With Tool Manager, you simply include lines in your script such as `# @require:python 3.12` and `# @require:pip tk` (for the Tk library).
  When someone installs and runs your plugin, Tool Manager will automatically create a Python 3.12 virtual environment for that script
  and install the **tk** package into it. The user doesn’t have to manually set up anything – it "just works."
  This ensures consistency across systems and saves developers from troubleshooting dependency issues.


- **Sharing and Collaborating on Tools**  
  In a team setting, you might have a repository of internal dev tools (shell scripts) that everyone uses.
  With Tool Manager, onboarding a new team member or setting up a new machine becomes much simpler.
  You can host your internal tools on a Git server (GitHub or elsewhere). A new developer just needs to install Tool Manager and
  run `tm-plugin-install yourcompany/your-tools` (or even provide the repository URL directly).
  The Tool Manager will clone the repo, register all the tools, and handle any declared dependencies.
  **This solves the "it works on my machine" problem** by codifying the setup in the plugin itself. Everyone ends up with the same set of tools configured the same way, improving reproducibility. Additionally, updates to the tools can be distributed by updating the plugin repository and having team members pull the latest version via Tool Manager commands.

In all these scenarios, Tool Manager acts as a facilitator – it reduces the manual effort needed to manage your shell tools.
Whether you are a solo developer keeping your dotfiles and scripts organized, or part of a team sharing utilities,
Tool Manager provides a high-level, benefits-focused solution. By **centralizing plugin management, automating environment setup, and offering easy commands**,
it lets you spend more time using or writing useful tools and less time configuring them.

## Prerequisites

Tool Manager relies on a few external commands being available on your system:

- `bash` **5.0** or newer (checked during bootstrap)
- `git` and `curl` for fetching plugins and updates
- `yq` for parsing YAML configuration files
- `envsubst` from the `gettext` package for environment variable substitution

If any of these commands are missing, the bootstrap scripts will provide a helpful error message.

# Installation

```bash
curl -s "https://raw.githubusercontent.com/codemucker/tool-manager/refs/heads/main/install.sh" | bash
```

or for a given version

```bash
curl -s  https://raw.githubusercontent.com/codemucker/tool-manager/refs/tags/0.0.1/install.sh | bash
```

You can also pass a version directly to the installer using `--version`:

```bash
curl -s "https://raw.githubusercontent.com/codemucker/tool-manager/refs/heads/main/install.sh" | bash -s -- --version 0.0.1
```

alternatively, clone this repo to `$HOME/.tool-manager` (or wherever you like) , and add the following to your `$HOME/.bashrc`

```bash
if [[ -f "$HOME/.tool-manager/.bashrc" ]]; then
  source "$HOME/.tool-manager/.bashrc"
fi
```
then either create a new shell or source the `$HOME/.tool-manager/.bashrc` to have it available in your shell

All the tool-manager commands start with `tm-`, so you can just type `tm-` and TAB, for auto complete

For all the tool commands installed, run `tm-help-commands` or `tm-help-commands-gui`

# Installing plugins

```bash
tm-plugin-install <name-of-plugin>                # you can pass -h or --help for options.
tm-plugin-install --vendor codemucker git-tools
tm-plugin-install codemucker/git-tools            # same as above
tm-plugin-install my:codemucker/git-tools         # will prefix 'my-' on all the git tools scripts
tm-plugin-install --prefix my --vendor codemucker --name git-tools # same as above
tm-plugin-install my:codemucker/git-tools@main    # will install from the main branch
tm-plugin-install my:codemucker/git-tools@0.1.0   # will install the 0.1.0 version
```

The 'prefix' is so that you can have the same plugin used in different contexts, say a 'my-git-each' and 'work-git-each',
with separate config, but the same codebase

If there is no plugin with the name in any of the plugin registry files, it will default with trying to install from github, using the form:

```
git@github.com:<vendor>/<plugin-name>.git
```

or you can install using a git url

```bash
tm-plugin-install <url-of-git-repo>
```

where the vendor name and plugin name will be auto extracted.

You can also have it list the available plugins, by providing no name and hit enter, it will show the list of available plugins

For the default available plugins, run:

```bash
tm-plugin-ls --help
tm-plugin-ls --available
tm-plugin-ls --installed
tm-plugin-ls --enabled
tm-plugin-ls --enabled --format plain
```

If you are developing plugins, you can call:

```bash
tm-edit <plugin-name> #(you can pass -h or --help for options)

# note: you can also pass in partial plugin names, such as 'git', and if there are multiple matches, it 
# will show a plugin selector prompt
```

or

```bash
tm-edit 
```
to get to the top plugin install dir.

If you have configured 'code' as your editor, it will auto generate a workspace file, which includes links to the plugin config/state/cache

If you add any new plugin scripts, you will need to call

```bash
tm-reload     # reloads all plugins
tm-reload <my-plugin> # reload just the given plugin (regen the wrapper scripts)
tm-reload <my-plugin> -f # force reload just the given plugin (disabled, then re-enables it)
```

for the wrapper scripts to be generated. This ensures your script env is set up
before invoking your real script.

To edit the plugin config, run:

```bash
tm-plugin-cfg # base config dir
tm-plugin-cfg codemucker/git-tools # config for the given plugin (partial name match supported)
tm-plugin-cfg my:codemucker/git-tools # config for the given plugin

# or the shorthand:

tm-edit-cfg # takes the same options as above)
```

# Dependencies

There is support for automatic python env provisioning, using either a python venv or a uv env. All you need to do is add '@require' directives
to your python scripts:

```python
#!/usr/bin/env env-tm-python        # note the shebang line. Required for now, but later we might not need it

# @require:venv     script          # none|script|plugin. 'Script' means one env just for this script, 'plugin' for a shared env for this plugin
# @require:python   3.12            # version of python to use. Notice how comments after directives are allowed
# @require:pip      tk              # a pip dependency
# @require:pip      ttkbootstrap    # another pip dependency
```

Support for node/deno/bash/java/kotlin etc dependencies is under development

Your script can end in '.py' or not. It will appear in your path without the extension

# Uninstall

To completely remove Tool Manager and all installed plugins, run:

```bash
tm-uninstall [--force]
```

The command executes `uninstall.sh` from your Tool Manager home
directory. It removes the `~/.tool-manager` folder, cleans any lines added
to `~/.bashrc` or `~/.profile` during installation, and unset all related environment variables.

Use the `--force` option to skip all confirmation prompts during uninstallation.

# Design

see [OVERVIEW.md](./docs/OVERVIEW.md)

# Contributing
Pull requests are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on setup, coding style, and the pull request workflow.
Feel free to open issues for feature requests or bug reports.
For larger contributions, please discuss the idea first to ensure it aligns with the project roadmap.

To run the test suite locally:

```bash
sudo apt-get update
sudo apt-get install -y shellcheck bats

shellcheck bin/*.sh bin-internal/*.sh
bats tests
```


# License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
