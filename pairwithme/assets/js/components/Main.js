'use strict';

import React from 'react';
import Layout from './Layout';
import SearchHeader from './SearchHeader';
import Board from './Board';

/* Main page that renders the feed and the search area
 */

export default class Main extends React.Component {
    fetchWines() {
        return fetch('/api/wines').then((response) => {
            return response.json()
        }).then((data) => {
            this.setState({
                'wines': data
            })
        })
    }

    searchWines(searchQuery) {
        let url = '/api/wines?search=' + searchQuery;

        return fetch(url).then((response) => {
            return response.json();
        }).then((data) => {
            this.setState({
                'wines': data
            })
        })
    }

    componentDidMount() {
        this.fetchWines()
    }

    render() {
        if (!this.state || !this.state.wines) {
            return null
        }

        return (
            <Layout>
                <SearchHeader
                    submitSearch={this.searchWines.bind(this)}
                />
                <div className="app-container">
                    <Board wines={this.state.wines}/>
                </div>
            </Layout>
        );
    }
}