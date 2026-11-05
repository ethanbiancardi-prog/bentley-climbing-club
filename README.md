# Bentley Climbing Club website

Live site: https://bentley-climbing-club.vercel.app

This site helps new members join on Campus Groups and finish their Central Rock Gym forms before an event. It's plain HTML and CSS, so there's nothing to install or build.

## Making an edit

Edit the files, commit on `main`, then run `./publish.sh`. It pushes to GitHub, deploys to Vercel, and only reports success once the live site matches your commit.

Commits made on GitHub don't go live until someone runs `./publish.sh`, because GitHub-triggered deploys are turned off. GitHub's notice to Vercel has arrived more than 25 minutes late, and a late deploy can put an old version back live. To turn them back on for other editors, delete `vercel.json`.

## What to keep up to date

Search `index.html` for these sections:

- **The club:** update the officers each year.
- **Where we climb:** gyms, addresses and the weekly session.
- **Do your CRG forms:** check the links still work, since CRG can change them.

Colors and layout are in `styles.css`.

## Please don't

Don't add anything private to this repo, such as passwords, member lists or signed waivers. The site should never collect waiver information. Those forms stay on Central Rock Gym's website.
