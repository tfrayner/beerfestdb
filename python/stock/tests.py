from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

from .models import Festival


class FestivalCRUDTests(APITestCase):
	def test_festival_crud_lifecycle(self):
		# list is empty
		url = reverse('festivals-list')
		r = self.client.get(url)
		self.assertEqual(r.status_code, status.HTTP_200_OK)

		# attempt to create without authentication (should be denied)
		payload = {'year': 2025, 'name': 'UnitTestFest', 'description': 'created by tests'}
		r = self.client.post(url, payload, format='json')
		self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

		# create an API user and token and retry
		user = User.objects.create_user('apiuser', password='testpass')
		token = Token.objects.create(user=user)
		self.client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)

		r = self.client.post(url, payload, format='json')
		self.assertEqual(r.status_code, status.HTTP_201_CREATED)
		fid = r.data['id'] if 'id' in r.data else r.data.get('festival_id', None)

		# retrieve
		detail = reverse('festivals-detail', args=[fid])
		r = self.client.get(detail)
		self.assertEqual(r.status_code, status.HTTP_200_OK)
		self.assertEqual(r.data['name'], 'UnitTestFest')

		# update
		r = self.client.patch(detail, {'description': 'patched'}, format='json')
		self.assertEqual(r.status_code, status.HTTP_200_OK)
		self.assertEqual(r.data['description'], 'patched')

		# delete
		r = self.client.delete(detail)
		self.assertEqual(r.status_code, status.HTTP_204_NO_CONTENT)


class BasicEndpointSmokeTests(APITestCase):
	def test_some_endpoints_exist(self):
		endpoints = [
			reverse('companies-list'),
			reverse('products-list'),
			reverse('casks-list'),
		]
		for ep in endpoints:
			r = self.client.get(ep)
			self.assertIn(r.status_code, (status.HTTP_200_OK, status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN))

	def test_create_requires_auth(self):
		# POST on a protected endpoint should require auth
		url = reverse('companies-list')
		r = self.client.post(url, {'name': 'AcmeCo'}, format='json')
		self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)
