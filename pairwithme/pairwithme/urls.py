"""pairwithme URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import url
from django.contrib import admin
from django.views.generic import TemplateView
from rest_framework.urlpatterns import format_suffix_patterns
from api import views

urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'^$', TemplateView.as_view(template_name='index.html')),
    url(r'^api/foods?$', views.FoodList.as_view()),
    url(r'^api/wines?$', views.WineList.as_view()),
    url(r'^api/foods/(?P<pk>[0-9]+)/$', views.FoodDetail.as_view()),
    url(r'^api/wines/(?P<pk>[0-9]+)/$', views.WineDetail.as_view()),
    # If none of the above match, we just render the original base page
    # Which will then route based off the React app
    # and show a 404 if necessary
    url(r'^(?:.*)/?$', TemplateView.as_view(template_name='index.html')),
]

urlpatterns = format_suffix_patterns(urlpatterns)
