# ProperData ChatGPT

This is a simplistic web interface for OpenAI's chat models, originally developed for the ProperData [2024 Summer Program](https://properdata.eng.uci.edu/events/privacyiot-ai-4/).

There is no backend. All the API calls are sent from the browser. You will need to supply your own API key in the settings.

## Deployment

This is a Flutter project. Please follow [this tutorial](https://docs.flutter.dev/get-started/install) to setup the Flutter toolchain.

Run the following to build the webpage:

```
$ flutter pub get
$ flutter build web
```

If you want to deploy the webpage under a subdirectory (instead of the website root), specify the directory using `--base-href` command:

```
$ flutter build web --base-href /subdirectory/
```

The built files are in `build/web/`. Serve them on a HTTPs website. That's it.

The current master branch is deployed through GitHub pages: <https://uci-networking-group.github.io/properdata-chatgpt/>
