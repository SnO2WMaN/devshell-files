# Devshell Files Maker
- [About](#about)
  - [Generate](#generate)
  - [Validate](#validate)
  - [Distribute](#distribute)
- [Instructions](#instructions)
  - [Generating files](#generating-files)
- [Examples](#examples)
  - [Dogfooding](#dogfooding)
- [Writing new modules](#writing-new-modules)
  - [Nix lang](#nix-lang)
  - [JSON as NIX](#json-as-nix)
  - [Modules](#modules)
    - [As function](#as-function)
    - [As object](#as-object)
    - [Options](#options)
  - [Sharing our module](#sharing-our-module)
  - [Document our module](#document-our-module)
- [Builtin modules](#builtin-modules)
- [TODO](#todo)
- [Issues](#issues)
- [See also](#see-also)

## About

Helps static file/configuration creation with [Nix](https://nixos.org/guides/how-nix-works.html) and [devshell](https://github.com/numtide/devshell).

There is a bunch of ways static file/configuration are hard, this will help you generate, validate and distribute JSON, YAML, TOML or TXT.

#### Generate

Your content will be defined in [Nix Language](https://github.com/tazjin/nix-1p), it means you can use variables, functions, imports, read files, etc.

The modular system helps layering configurations, hiding complexity and making it easier for OPS teams.

#### Validate

Your content [modules](https://nixos.org/manual/nixos/stable/index.html#ex-module-syntax) could optionally be well defined and type checked in build proccess with this same tool.

Or you could use [Nix](https://nixos.org/manual/nix/stable/) as package manager and [install any tool](https://search.nixos.org/packages?query=validator) to validate your configuration (ie integrating it with existing JSON Schema).


#### Distribute

Nix integrates well with git and http, it could be also used to read JSON, YAML, TOML, zip and gz files.

In fact Nix isn't a configuration tool but a package manger, we are only using it as configuration tool because the language is simple and flexible.

With help of [Nix](https://nixos.org/guides/how-nix-works.html) and [devshell](https://github.com/numtide/devshell) you could install any development or deployment tool of its [80 000](https://search.nixos.org/) packages.

## Instructions

Installing [Nix](https://nixos.wiki/wiki/Flakes)

```sh
curl -L https://nixos.org/nix/install | sh

nix-env -f '<nixpkgs>' -iA nixUnstable

mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Configuring new projects:

```sh
nix flake new -t github:cruel-intentions/devshell-files my-project
cd my-project
git init
git add .
```

Configuring existing projects:

```sh
nix flake new -t github:cruel-intentions/devshell-files ./
git add flake.nix, flake.lock project.nix
```

#### Generating files:

```sh
nix develop --build
```

or entering in shell with all commands and alias

```sh
nix develop -c $SHELL
# to list commands and alias
# now run: menu 
```

### Examples

Creating JSON, TEXT, TOML or YAML files

```nix
# examples/hello.nix
#
# this is one nix file
{
  files.json."/generated/hello.json".hello = "world";
  files.toml."/generated/hello.toml".hello = "world";
  files.yaml."/generated/hello.yaml".hello = "world";
  files.hcl."/generated/hello.hcl".hello = "world";
  files.text."/generated/hello.txt" = "world";
}

```

Your file can be complemented with another module

```nix
# examples/world.nix
# almost same as previous example
# but show some language feature
let 
  name = "hello"; # a variable
in
{
  files = {
    json."/generated/${name}.json".baz = ["foo" "bar" name];
    toml."/generated/${name}.toml".baz = ["foo" "bar" name];
    yaml = {
      "/generated/${name}.yaml" = {
        baz = [
          "foo"
          "bar"
          name
        ];
      };
    };
  };
}

```

Content generated by those examples are in [generated](./generated/)

```YAML
# ie ./generated/hello.yaml
baz:
  - foo
  - bar
  - hello
hello: world

```

### Dogfooding

This project is configured by module [project.nix](./project.nix)

```nix
# ./project.nix
{
  # import other modules
  imports = [
    ./examples/hello.nix
    ./examples/world.nix
    ./examples/readme.nix
    ./examples/gitignore.nix
    ./examples/license.nix
    ./examples/docs.nix
    ./examples/book.nix
    ./examples/services.nix
    ./examples/nim.nix
  ];
  # install development or deployment tools
  # now we can use 'convco' command https://convco.github.io
  # look at https://search.nixos.org for more tools
  files.cmds.convco = true;
  # now we can use 'feat' command (alias to convco)
  files.alias.feat = ''convco commit --feat $@'';
  files.alias.fix  = ''convco commit --fix  $@'';
  files.alias.docs = ''convco commit --docs $@'';
}

```

This README.md is also a module defined as above

```nix
# There is a lot things we could use to write static file
# Basic intro to nix language https://github.com/tazjin/nix-1p
# Some nix functions https://teu5us.github.io/nix-lib.html
{lib, ...}:
{
  files.text."/README.md" = builtins.concatStringsSep "\n" [
    "# Devshell Files Maker"
    (builtins.readFile ./readme/toc.md)
    (builtins.readFile ./readme/about.md)
    (builtins.readFile ./readme/installation.md)
    (builtins.import ./readme/examples.nix)
    ((builtins.import ./readme/modules.nix) lib)
    (builtins.readFile ./readme/todo.md)
    (builtins.readFile ./readme/issues.md)
    (builtins.readFile ./readme/seeAlso.md)
  ];
}

```

Our .gitignore is defined like this
```nix
# ./examples/gitignore.nix
{
  # create my .gitignore coping ignore patterns from
  # github.com/github/gitignore
  files.gitignore.enable = true;
  files.gitignore.template."Global/Archives" = true;
  files.gitignore.template."Global/Backup"   = true;
  files.gitignore.template."Global/Diff"     = true;
  files.gitignore.pattern.".direnv"          = true;
  files.gitignore.pattern.".data"            = true;
}

```

And our LICENSE file is
```nix
# ./examples/license.nix
{
  # LICENSE file creation
  # using templates from https://github.com/spdx/license-list-data
  files.license.enable = true;
  files.license.spdx.name = "MIT";
  files.license.spdx.vars.year = "2021";
  files.license.spdx.vars."copyright holders" = "Cruel Intentions";
}

```

## Writing new modules

### Nix lang

Jump this part if aready know Nix Lang, if don't there is a small concise content of [Nix Lang](https://github.com/tazjin/nix-1p).

If one page is too much to you, the basic is:

- `:` defines a new function, `arg: "Hello ''${arg}"`
- that's why we use `=` instaed of `:`, `{ attr-key = "value"; }`
- `;` instead of `,` and they **aren't optional**
- array aren't separated by `,` ie. `[ "some" "value" ]`


### JSON as NIX

| name | JSON | NIX |
| -- | ---- | ---- |
| null | `null` | `null` |
| bool | `true` | `true` |
| int | `123` | `123` |
| float | `12.3` | `12.3` |
| string | `"string"` | `"string"` |
| array | `["some","array"]` | `["some" "array"]` |
| object | `{"some":"value"}` | `{ some = "value"; }` |
| multiline-string | | `''... multiline string ... ''` |
| variables | | `let my-var = 1; other-var = 2; in my-var + other-var` |
| function | | `my-arg: "Hello ${my-arg}!"` |
| variable-function | | `let my-function = my-arg: "Hello ${my-arg}!"; in ...` |
| calling-a-function | | `... in my-function "World"` |

### Modules

Modules could be defined in two formats:

#### As function:

These functions has at least these params: 

- `config` with all evaluated configs values, 
- `pkgs` with all [nixpkgs](https://search.nixos.org/) available.
- `lib` [library](https://teu5us.github.io/nix-lib.html#nixpkgs-library-functions) of useful functions.
- And may receive other named params (use `...` to ignore them)

```nix
{ config, pkgs, lib, ... }:  # parms
{ imports = []; config = {}; options = {}; }
```

#### As object:

```nix
{ imports = []; config = {}; options = {}; }
```

All those attributes are optional

- imports: array with paths to other modules
- config: object with user configurations
- options: object with our config type definition

We adivise you to divide your modules in two files:
- One mostly with options, where your definition goes
- Other with config, where your information goes

It has two advantages, you could share options definitions across projects more easily.

And it hides complexity, [hiding complexity is what abstraction is all about](http://mourlot.free.fr/english/fmtaureau.html),
we didn't share options definitions across projects to type less, but because we could reuse an abstraction that helps hiding complexity.

#### Imports

Points to other files we want import in this module

```nix
{ 
  imports = [
    ./gh-actions-options.nix
    ./some-other-module.nix
  ];
}
```

#### Config

Are values to your options

```nix
{
  config.gh-actions.ci-cd.pre-build = "npm i";
}
```

Note that if your file has only imports and config we could ommit `config`.

And this file is the same

```nix
{
  gh-actions.ci-cd.pre-build = "npm i";
}
```

#### Options

Them we need to learn how to create options.

Lets start with simple example:

We need create our github action file, it could be done as something like this:

```nix
{
  files.yaml."./.github/workflows/ci-cd.yaml" = {
    on = "push";
    # ... rest of github action definition
  };
}
```

As we can see, we aren't hiding complexity and we may copy and past it in every project.

Since most of our config are just: 'get code', 'build', 'test', 'install'

What project user (maybe us) really needs to define is:

```nix
{
  gh-actions.ci-cd.pre-build = "npm i";
  gh-actions.ci-cd.build = "npm run build";
  gh-actions.ci-cd.test = "npm run test";
  gh-actions.ci-cd.deploy = "aws s3 sync ./build s3://some-s3-bucket";
  # in the best of worlds this two aren't required but craw command
  # to seek dependecies is hard (we sucked at hiding complexity)
  files.cmds.aws-cli = true;
  files.cmds.nodejs-14_x = true;
}
```

Now we're hiding complexity, not all, but some.

If we add this to our project.nix we discover that there is no `gh-actions` config available.

To create it we add `options` definition of that.

```nix
{ lib, ...}:
{
  options.gh-actions.ci-cd = lib.mkOption {
    type = lib.types.submodule {
      options.pre-build = lib.mkOption {
        type = lib.types.str;
        default = "echo pre-building";
        example = "npm i";
        description = "Command to run before build";
      };
      options.build = lib.mkOption {
        type = lib.types.str;
        default = "echo building";
        example = "npm run build";
        description = "Command to run as build step";
      };
      options.test = lib.mkOption {
        type = lib.types.str;
        default = "echo testing";
        example = "npm test";
        description = "Command to run as test step";
      };
      options.deploy = lib.mkOption {
        type = lib.types.str;
        default = "echo deploying";
        example = "aws s3 sync ./build s3://my-bucket";
        description = "Command to run as deploy step";
      };
    };
    default = {};
    description = "Configure your github actions CI/CD";
  };
}
```

Good, that is it, now we can set config as we said before, but it does nothing, it doesn't create our yaml file.

Usually people put the next part in same file of previous code, it isn't a requirement, and spliting it here make it simplier to explain.

The cool point is that to create our yaml file we only need one config like we proposed first.

```nix
{ lib, config, ... }:
let
  cfg = config.gh-actions.ci-cd;
  cmd = step: "nix develop --command gh-actions-ci-cd-${step}";
in
{ 
  imports = [ ./gh-actions-options.nix ];
  files.alias = lib.mkIf cfg.enable {
    gh-actions-ci-cd-pre-build = cfg.pre-build;
    gh-actions-ci-cd-build = cfg.build;
    gh-actions-ci-cd-test = cfg.test;
    gh-actions-ci-cd-deploy = cfg.deploy;
  };
  files.yaml."/.github/workflows/ci-cd.yaml" = lib.mkIf cfg.enable {
    on = "push";
    jobs.ci-cd.runs-on = "ubuntu-latest";
    jobs.ci-cd.steps = [
      { uses = "actions/checkout@v2.4.0"; }
      { 
        uses = "cachix/install-nix-action@v15";
        "with".nix_path = "channel:nixos-unstable";
        "with".extra_nix_config = ''
          access-tokens = github.com=${"$"}{{ secrets.GITHUB_TOKEN }}
        '';
      }
      # this config comes from arguments
      { run = cmd "pre-build"; name = "Pre Build"; }
      { run = cmd "build"; name = "Build"; }
      { run = cmd "test"; name = "Test"; }
      { run = cmd "deploy"; name = "Deploy"; }
    ];
  };
}
```

Now we only need to import it on our project and set 'pre-build', 'build', 'test' and 'deploy' configs

```nix
{
  gh-actions.ci-cd.enable = true;
  gh-actions.ci-cd.deploy = "echo 'habemus lux'";
}
```

If we try to set something that is not a string to it, one error will raise, typecheking it.

There are [other types](https://nixos.org/manual/nixos/stable/index.html#sec-option-types) that can be used (some of them):
- lib.types.bool 
- lib.types.path 
- lib.types.package 
- lib.types.int 
- lib.types.ints.unsigned
- lib.types.ints.positive
- lib.types.ints.port
- lib.types.ints.between
- lib.types.str
- lib.types.lines
- lib.types.enum
- lib.types.submodule
- lib.types.nullOr (typed nullable)
- lib.types.listOf (typed array)
- lib.types.attrsOf (typed hash map)
- lib.types.uniq (typed set)

### Sharing our module

Now to not just copy and past it everywhere, we could create a git repository, ie. [gh-actions](https://github.com/cruel-intentions/gh-actions)

Then we could let nix manage it for us adding it to flake.nix file like

```nix
{
  description = "Dev Environment";

  inputs.dsf.url = "github:cruel-intentions/devshell-files";
  inputs.gha.url = "github:cruel-intentions/gh-actions";
  # for private repository use git url
  # inputs.gha.url = "git+ssh://git@github.com/cruel-intentions/gh-actions.git";

  outputs = inputs: inputs.dsf.lib.mkShell [
    "${inputs.gha}/gh-actions.nix"
    ./project.nix
  ];
}
```

Or manage version adding it directly to project.nix (or any other module file)

```nix
{
  imports = 
    let gh-actions = builtins.fetchGit {
      url = "git+ssh://git@github.com/cruel-intentions/gh-actions.git";
      ref = "master";
      rev = "46eead778911b5786d299ecf1a95c9ed4c130844";
    };
    in [
      "${gh-actions}/gh-actions.nix"
    ];
}
```

### Document our module

To documento our modules is simple, we just need to use `config.files.docs` as follow

```nix
# examples/docs.nix

{lib, pkgs, ...}:
{
  files.docs."/gh-pages/src/modules/alias.md".modules     = [ ../modules/alias.nix     ];
  files.docs."/gh-pages/src/modules/cmds.md".modules      = [ ../modules/cmds.nix      ];
  files.docs."/gh-pages/src/modules/files.md".modules     = [ ../modules/files.nix     ];
  files.docs."/gh-pages/src/modules/git.md".modules       = [ ../modules/git.nix       ];
  files.docs."/gh-pages/src/modules/gitignore.md".modules = [ ../modules/gitignore.nix ];
  files.docs."/gh-pages/src/modules/hcl.md".modules       = [ ../modules/hcl.nix       ];
  files.docs."/gh-pages/src/modules/json.md".modules      = [ ../modules/json.nix      ];
  files.docs."/gh-pages/src/modules/mdbook.md".modules    = [ ../modules/mdbook.nix    ];
  files.docs."/gh-pages/src/modules/spdx.md".modules      = [ ../modules/spdx.nix      ];
  files.docs."/gh-pages/src/modules/text.md".modules      = [ ../modules/text.nix      ];
  files.docs."/gh-pages/src/modules/toml.md".modules      = [ ../modules/toml.nix      ];
  files.docs."/gh-pages/src/modules/yaml.md".modules      = [ ../modules/yaml.nix      ];
  files.docs."/gh-pages/src/modules/serices.md".modules   = [ ../modules/services.nix  ];
  files.docs."/gh-pages/src/modules/batata.md".modules    = [ ./batata.nix             ];
  files.docs."/gh-pages/src/modules/batata.md".evalModulesArgs = {
    specialArgs.lib = lib // { my = v: v; };
    specialArgs.inputs = { a = "b";};
  };
}



```



<details>
<summary>We could also generate a mdbook with it</summary>
<br>


```nix
# examples/book.nix

{lib, ...}:
let
  project = "devshell-files";
  author = "cruel-intentions";
  org-url = "https://github.com/${author}";
  edit-path = "${org-url}/${project}/edit/master/guide/{path}";
in
{
  files.mdbook.enable = true;
  files.mdbook.authors = ["Cruel Intentions <${org-url}>"];
  files.mdbook.language = "en";
  files.mdbook.gh-author = author;
  files.mdbook.gh-project = project;
  files.mdbook.multilingual = false;
  files.mdbook.title = "Nix DevShell Files Maker";
  files.mdbook.output.html.fold.enable = true;
  files.mdbook.output.html.no-section-label = true;
  files.mdbook.output.html.site-url = "/${project}/";
  files.mdbook.output.html.git-repository-icon = "fa-github";
  files.mdbook.output.html.git-repository-url = "${org-url}/${project}";
  files.mdbook.output.html.edit-url-template = edit-path;
  files.mdbook.summary = builtins.readFile ./summary.md;
  files.text."/gh-pages/src/introduction.md" = builtins.readFile ./readme/about.md;
  files.text."/gh-pages/src/installation.md" = builtins.readFile ./readme/installation.md;
  files.text."/gh-pages/src/examples.md" = builtins.import ./readme/examples.nix;
  files.text."/gh-pages/src/modules.md" = "## Writing new modules";
  files.text."/gh-pages/src/nix-lang.md" = builtins.readFile ./readme/modules/nix-lang.md;
  files.text."/gh-pages/src/json-nix.md" = builtins.import ./readme/modules/json-vs-nix.nix lib;
  files.text."/gh-pages/src/module-spec.md" = builtins.readFile ./readme/modules/modules.md;
  files.text."/gh-pages/src/share.md" = builtins.readFile ./readme/modules/share.md;
  files.text."/gh-pages/src/document.md" = builtins.import ./readme/modules/document.nix;
  files.text."/gh-pages/src/builtins.md" = builtins.readFile ./readme/modules/builtins.md;
  files.text."/gh-pages/src/todo.md" = builtins.readFile ./readme/todo.md;
  files.text."/gh-pages/src/issues.md" = builtins.readFile ./readme/issues.md;
  files.text."/gh-pages/src/seeAlso.md" = builtins.readFile ./readme/seeAlso.md;
  files.gitignore.pattern."gh-pages" = true;
  files.alias.publish-as-gh-pages-local = ''
    # same as publish-as-gh-pages but works local
    ORIGIN=`git remote get-url origin`
    cd gh-pages
    mdbook build
    cd book
    git init .
    git add .
    git checkout -b gh-pages
    git commit -m "docs(gh-pages): update gh-pages" .
    git remote add origin $ORIGIN
    git push -u origin gh-pages --force
  '';  
}

```


</details>


And publish this mdbook to github pages with `book-as-gh-pages` alias.


## Builtin Modules

Builtin Modules are modules defined with this same package.

They are already included when we use this package.

- `files.alias`, create bash script alias
- `files.cmds`, install packages from [nix repository](https://search.nixos.org/)
- `files.docs`, convert our modules file into markdown using [nmd](https://gitlab.com/rycee/nmd)
- `files.git`, configure git with file creation
- `files.gitignore`, copy .gitignore from [templates](https://github.com/github/gitignore/)
- `files.hcl`, create HCL files with nix syntax
- `files.json`, create JSON files with nix syntax
- `files.mdbook`, convert your markdown files to HTML using [mdbook](https://rust-lang.github.io/mdBook/)
- `files.nim`, similar to `files.alias`, but compiles [Nim](https://github.com/nim-lang/Nim/wiki#getting-started) code
- `files.services`, process supervisor for development services using [s6](http://skarnet.org/software/s6)
- `files.spdx`, copy LICENSE from [templates](https://github.com/spdx/license-list-data/tree/master/text)
- `files.text`, create free text files with nix syntax
- `files.toml`, create TOML files with nix syntax
- `files.yaml`, create YAML files with nix syntax


Our [documentation](https://cruel-intentions.github.io/devshell-files/) is generated by `files.text`, `files.docs` and `files.mdbook`



## TODO

- Add modules for especific cases:
  - ini files
  - most common ci/cd configuration
- Verify if devshell could add it as default

## Issues

This project uses git as version control, if your are using other version control system it may not work.

### See also
* [Nix](https://nixos.org/)
* [DevShell](https://github.com/numtide/devshell)
* [Home Manager](https://github.com/nix-community/home-manager)
* [Nix Ecosystem](https://nixos.wiki/wiki/Nix_Ecosystem)
* [Makes](https://github.com/fluidattacks/makes)
* [Nix.Dev](https://nix.dev/)
* [Nixology](https://www.youtube.com/watch?v=NYyImy-lqaA&list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs)
