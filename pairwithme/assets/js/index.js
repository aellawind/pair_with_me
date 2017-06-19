import ReactDOM from 'react-dom';
import React, { Component } from 'react'
import { Router, Route, Link, IndexRoute, browserHistory} from 'react-router';
import routes from './routes';
import css from './index.css';


class App extends Component {
    render() {
        return (
            <Router history={browserHistory} routes={routes} />
        )
    }
}

ReactDOM.render(<App />, document.getElementById('container'));

