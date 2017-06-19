'use strict';

import React from 'react'
import { Route, IndexRoute } from 'react-router'
import Layout from './components/Layout';
import Main from './components/Main';
import Listing from './components/Listing';
import NotFoundPage from './components/NotFound';

const routes = (
    <Route path="/" component={Layout}>
    	<IndexRoute component={Main} />
    	<Route path="listing/:listingId" component={Listing} />
        <Route path="*" component={NotFoundPage} /> // * Maps to all other pages
    </Route>
);

export default routes;