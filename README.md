# opencwb

A project to provide public and open API for weather information in Taiwan.

## Directory Layout

    _public/                  --> Contains generated file for servering the app
                                  These files should not be edited directly
    app/                      --> files for building static content using brunch

    lib/                      --> common library
    server/                   --> zappajs-based server

## to start a server

make sure you have mongodb

    npm i
    make run

and you should see a localhost server to connect to

you might want to run "brunch w" to watch files during development
