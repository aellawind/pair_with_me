'use strict';

import React from 'react';
import Layout from './Layout';
import Header from './Header';
import Board from './Board';

/* Main page that renders the feed and the search area
 */

export default class Main extends React.Component {
    render() {
        return (
            <Layout>
                <Header />
                <div className="app-container">
                    Put the feed in here.
                    <Board />
                </div>
            </Layout>
        );
  }
}