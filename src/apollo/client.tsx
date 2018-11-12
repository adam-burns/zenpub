import ApolloClient from 'apollo-boost';

import resolvers from './resolvers';
import User from '../types/User';
import typeDefs from './typeDefs';
import { NotificationType } from '../components/elements/Notification/Notification';

export const DUMMY_USER = {
  __typename: 'User',
  id: 0,
  username: 'MoodlerJoe',
  email: 'moodlerjoe@example.com',
  emojiId: '',
  role: '',
  location: '',
  language: 'en-gb',
  interests: [],
  languages: [],
  notifications: [
    {
      __typename: 'Notification',
      id: 0,
      when: 'Just now',
      content: `
      <p>
        We think you might find the collection
        <strong>Lenin at Finland Station</strong> interesting
      </p>
    `,
      type: NotificationType.moodlebot
    },
    {
      __typename: 'Notification',
      id: 1,
      when: '20 minutes ago',
      content: `
      <p>
        <strong>Ibrahima</strong> commented on the collection
        <strong>Hyperinflation in Weimar Germany</strong>
      </p>
    `,
      type: NotificationType.collection
    },
    {
      __typename: 'Notification',
      id: 2,
      when: '1 hour ago',
      content: `
      <p>
        <strong>Liezel</strong> commented on your post in
        <strong>Progressive European Historians</strong>
      </p>
    `,
      type: NotificationType.community
    }
  ]
} as User;

export default new ApolloClient({
  clientState: {
    typeDefs,
    defaults: {
      user: {
        __typename: 'User',
        isAuthenticated: false,
        data: null
      }
    },
    resolvers
  }
});