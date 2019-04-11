const webpack = require("webpack");
const path = require("path");
const fs = require("fs");
const autoprefixer = require('autoprefixer');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
const scssLoader = new ExtractTextPlugin('[name].[chunkhash:6].css');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var CleanPlugin = require('clean-webpack-plugin');

const THEME_NAME = "yilia";
const OUTPUT_DIR = 'source';

// init `yilia_config.yml` in root dir,
if (!fs.existsSync(path.resolve(__dirname, '..', 'yilia_config.yml'))) {
  let theme_config = fs.readFileSync(path.resolve(__dirname, '_config.yml'));
  fs.writeFileSync(path.resolve(__dirname, '..', 'yilia_config.yml'), theme_config);
  // node v8.5+ fs.copyFileSync(path.resolve(__dirname, '_config.yml'), path.resolve(__dirname, '..', 'yilia_config.yml'));
}
let target_dir = path.resolve(__dirname, '../../', 'themes', THEME_NAME);

var minifyHTML = {
  collapseInlineTagWhitespace: true,
  collapseWhitespace: true,
  minifyJS:true
}

module.exports = {
  entry: {
    main: "./source-src/js/main.js",
    slider: "./source-src/js/slider.js",
    mobile: ["babel-polyfill", "./source-src/js/mobile.js"]
  },
  output: {
    path: path.resolve(target_dir, OUTPUT_DIR),
    publicPath: "./",
    filename: "[name].[chunkhash:6].js"
  },
  module: {
    rules: [
    {
      test: /\.js$/, //es6 => es5
      include: [
        path.resolve(__dirname, 'source-src')
      ],
      exclude: /node_modules/,
      use: 'babel-loader'
    },
    {
      test: /\.html$/,
      use: 'html-loader'
    }, 
    {
      test: /\.(scss|sass|css)$/,
      use: ['style-loader'].concat(scssLoader.extract([{
        loader: 'css-loader',
        options: {
          importLoaders: 2
        }
      }, {
        loader: 'postcss-loader',
        options: {
          ident: 'postcss',
          plugins: (loader) => [require('autoprefixer')()]
        }
      }, 'sass-loader']))
     
    }, {
      test: /\.(gif|jpg|png)\??.*$/,
      use: [{
        loader: 'url-loader',
        options: {
          limit: 500,
          name: 'img/[name].[ext]'
        }
      }]
    }, {
      test: /\.(woff|svg|eot|ttf)\??.*$/,
      use: [{
        loader: 'file-loader',
        options: {
          name: 'fonts/[name].[hash:6].[ext]'
        }
      }]
    }]
  },
  plugins: [
    new ExtractTextPlugin('[name].[chunkhash:6].css'),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': '"production"'
    }),
    new HtmlWebpackPlugin({
      inject: false,
      cache: false,
      minify: minifyHTML,
      template: path.resolve(__dirname, 'source-src', 'script.ejs'),
      filename: path.resolve(target_dir, 'layout', '_partial', 'script.ejs')
    }),
    new HtmlWebpackPlugin({
      inject: false,
      cache: false,
      minify: minifyHTML,
      template: path.resolve(__dirname, 'source-src', 'css.ejs'),
      filename: path.resolve(target_dir, 'layout', '_partial', 'css.ejs')
    })
  ],
  watch: true
}

if (process.env.NODE_ENV === 'production') {
  module.exports.devtool = '#source-map'
  module.exports.plugins = (module.exports.plugins || []).concat([
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"production"'
      }
    }),
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        warnings: false
      }
    }),
    new webpack.optimize.OccurenceOrderPlugin(),
    new CleanPlugin('builds')
  ])
}