---
title: "Stowing Dotfiles"
date: 2020-10-01T21:47:23+01:00
draft: false
description: "Using GNU's Stow tool to sync your dotfile configuration across machines with git!"
tags: 
    - tools
categories: 
    - development
description: Test
---

I recently found about a piece of GNU software called Stow[^1].

It lets you manage your dotfiles in a really simple way, meaning you can put them in git and have them easily transferable between machines.

What it will do is let you move all your dotfiles into a directory, and then symlink them back into your home directory with a simple command.

From the man page[^2]:

> Stow is a symlink farm manager which takes distinct sets of software and/or data located in separate
directories on the filesystem, and makes them all appear to be installed in a single directory tree.

## Set up

First you'll need to install `Stow` using your package manager of choice. I use a Mac so it's just:

```sh
brew install stow
```

Then you'll need to create a directory in which to store your dotfiles, and directories within it to keep them separate.

```sh
mkdir ~/dotfiles;
mkdir ~/dotfiles/git;
mkdir ~/dotfiles/zsh;
```

Move your dotfiles into the relevant directories:

```sh
mv ~/.gitconfig ~/dotfiles/git;
mv ~/.zshrc ~/dotfiles/zsh;
mv ~/.zshenv ~/dotfiles/zsh;
```

## The magic part

Now here's where `stow` comes in. Stow will, given a source directory and a destination directory, create symlinks in the destination directory to all the files in the source directory.

From within `~/dotfiles`

```sh
stow -R -t ~ git
```

Here's an explanation of what that command is doing:

1. `-R` means "restow". This will overwrite your symlinks, say if you've updated your dotfiles on another machine and want to sync them to your current machine From the manpage:
    > Restow packages (first unstow, then stow again). This is useful for pruning obsolete symlinks
    from the target tree after updating the software in a package.

2. `-t ~` is the target directory. This is where the symlinks will be created.

3. The final argument is the directory containing the files to be symlinked to.

Putting it all together, running `stow -R -t ~ git` will create a symlink in your home directory to `~/dotfiles/git/.gitconfig`.

And it's that simple.

Now you can `git init` inside your `~/dotfiles` directory, push them up to your remote and have them immediately available on all your machines.

Here's a simple bit of bash that will stow all the dotfiles in your home directory from your `~/dotfiles` repo:

```sh
for d in */ ; do
    stow -R -t ~ "$d"
done
```

For reference, [here are my dotfiles on GitHub](https://github.com/mathieuhendey/dotfiles).

[^1]: https://www.gnu.org/software/stow/
[^2]: https://linux.die.net/man/8/stow
