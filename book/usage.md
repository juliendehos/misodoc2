
# Usage

## What does a MisoDoc2's documentation look like?

Well, you are reading one, actually. :scream:

On the left side, you have the summary panel, where you can choose the file to
display on the right side. You also have three icons, at the bottom of the
page, to go to the previous page, to the top of the current page or to the next
page. Finally, at the top of the page, you can click on the first icon to
show/hide the summary panel. 


## How to use MisoDoc2?

- Create a `book` folder containing a `summary.md` file and the `static` folder
  provided by MisoDoc2 (see the [misodoc2/book
  example](https://github.com/juliendehos/misodoc2/tree/main/book))

- Run the MisoDoc2 server, for example using the docker image:

    ```
    docker run --rm -it -p 3000:3000 -v ./book:/book juliendehos/misodoc2:serve
    ```

- Open a browser and go to `localhost:3000`.

- Edit/add your files in the `book` folder. You can see the rendered
  documentation in the browser. Add links to your MD files in the `summary.md`
  file to include them in the summary panel. 

- When you are satisfied with your documentation, you can generate static HTML
  files, for example using the docker image:

    ```
    docker run --rm -it -v ./book:/book -v ./output:/output juliendehos/misodoc2:render
    ```

And that's it. :rocket:


## How to customize a MisoDoc2's documentation?

MisoDoc2 is still a work-in-progress and has a lot of room for improvement. So
you will likely need to modify the code and build your own version of it.

