/*

 Quick-start

 1. Install gulp, gulp-shell and gulp-changed via npm
 2. Save this file to your project dir and rename it to 'gulpfile.js'
 3. Run gulp to upload only changed files to your nodemcu

 Notes
 This script assumes that your *.lua files reside in a subdirectoty called 'src'. Change accordingly.
 Also each *.lua file is copied to a 'dist' directory. This is to keep track of the last time the file was uploaded.
*/

var gulp  = require('gulp');
var shell = require('gulp-shell');
var changed = require('gulp-changed');
var flatten = require('gulp-flatten');
var luaminify = require('gulp-luaminify');

var watcher = gulp.watch('src/**/*.lua', ["upload"]);
watcher.on("change", function(event) {
  console.log("File " + event.path + " was " + event.type + ", running tasks...");
});

gulp.task("default", ["upload"], function() {
  console.log("Build Finished");
});

gulp.task("upload", ["copy"], function() {
  var result = gulp.src(["dist/!*.lua", "dist/#_*"])
    .pipe(changed("dist/sent", {hasChanged: changed.compareSha1Digest}))
    .pipe(shell("echo uploading dist/<%= file.relative %>"))
    .pipe(shell("nodemcu-tool upload --remotename=<%=file.relative%> dist/<%=file.relative%>"))
    .pipe(gulp.dest("dist/sent"));
  return result;
});

gulp.task("copy", ["precompile"], function() {
  var result = gulp.src("src/**/!*.lua")
    .pipe(changed("dist"))
    .pipe(flatten())
    .pipe(luaminify())
    .pipe(gulp.dest("dist"));
  return result;
});

gulp.task("precompile", function(callback) {
  //precompile modules (prefixed by "_")
  var result = gulp.src("src/**/_*.lua")
    .pipe(flatten())
    .pipe(changed("dist/process"))
    .pipe(luaminify())
    .pipe(gulp.dest("dist/process"))
    .pipe(shell("cd dist/process && lua ../../tools/flashmod-prepare.lua <%= file.relative %> .."));
  return result;
});
