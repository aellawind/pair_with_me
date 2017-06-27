'use strict';

import React from 'react';
import ListingHeader from './ListingHeader';
import Board from './Board';

/* Listing page for either the food or the wine
 */
export default class Listing extends React.Component {
    fetchWine() {
    	const url = `/api/wines/${this.props.params.wine_id}/`
        return fetch(url).then((response) => {
            return response.json()
        }).then((data) => {
            this.setState({
                'wine': data
            })
        })
    }

    componentDidMount() {
        this.fetchWine()
    }

    render() {
        if (!this.state || !this.state.wine) {
            return null
        }

        return (
            <div className="listing">
            	<ListingHeader />
            	<div className="board">{this.props.params.wine_id}</div>
            </div>
        );
  }
}