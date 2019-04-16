import React from 'react';
import styled from '../../../themes/styled';
import { compose } from 'recompose';
import { graphql, OperationOption } from 'react-apollo';
const {
  joinCollectionMutation
} = require('../../../graphql/joinCollection.graphql');
const {
  undoJoinCollectionMutation
} = require('../../../graphql/undoJoinCollection.graphql');
import gql from 'graphql-tag';
import { Eye, Unfollow } from '../Icons';
import { Trans } from '@lingui/macro';

const getFollowedCollectionsQuery = require('../../../graphql/getFollowedCollections.graphql');

interface Props {
  joinCollection: any;
  leaveCollection: any;
  id: string;
  followed: boolean;
  externalId: string;
}

const withJoinCollection = graphql<{}>(joinCollectionMutation, {
  name: 'joinCollection'
  // TODO enforce proper types for OperationOption
} as OperationOption<{}, {}>);

const withLeaveCollection = graphql<{}>(undoJoinCollectionMutation, {
  name: 'leaveCollection'
  // TODO enforce proper types for OperationOption
} as OperationOption<{}, {}>);

const Join: React.SFC<Props> = ({
  joinCollection,
  id,
  leaveCollection,
  externalId,
  followed
}) => {
  if (followed) {
    return (
      <Span
        unfollow
        onClick={() =>
          leaveCollection({
            variables: { collectionId: id },
            update: (proxy, { data: { undoJoinCollection } }) => {
              const fragment = gql`
                fragment Res on Collection {
                  followed
                }
              `;
              let collection = proxy.readFragment({
                id: `Collection:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res'
              });
              collection.followed = !collection.followed;

              let followedCollections = proxy.readQuery({
                query: getFollowedCollectionsQuery,
                variables: {
                  limit: 15
                }
              });
              let index = followedCollections.me.user.followingCollections.edges.findIndex(
                e => e.node.id === externalId
              );
              if (index === -1) {
                followedCollections.me.user.followingCollections.edges.unshift(
                  collection
                );
              }
              followedCollections.me.user.followingCollections.edges.splice(
                index,
                1
              );
              proxy.writeQuery({
                query: getFollowedCollectionsQuery,
                variables: {
                  limit: 15
                },
                data: followedCollections
              });
              proxy.writeFragment({
                id: `Collection:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res',
                data: collection
              });
            }
          })
            .then(res => {
              console.log(res);
            })
            .catch(err => console.log(err))
        }
      >
        <Unfollow width={18} height={18} strokeWidth={2} color={'#1e1f2480'} />
        <Trans>Unfollow</Trans>
      </Span>
    );
  } else {
    return (
      <Span
        onClick={() =>
          joinCollection({
            variables: { collectionId: id },
            update: (proxy, { data: { joinCollection } }) => {
              const fragment = gql`
                fragment Res on Collection {
                  followed
                }
              `;
              let collection = proxy.readFragment({
                id: `Collection:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res'
              });
              collection.followed = !collection.followed;

              let followedCollections = proxy.readQuery({
                query: getFollowedCollectionsQuery,
                variables: {
                  limit: 15
                }
              });
              if (followedCollections) {
                let index = followedCollections.me.user.followingCollections.edges.findIndex(
                  e => e.node.id === externalId
                );
                if (index === -1) {
                  followedCollections.me.user.followingCollections.edges.unshift(
                    collection
                  );
                }
                proxy.writeQuery({
                  query: getFollowedCollectionsQuery,
                  variables: {
                    limit: 15
                  },
                  data: followedCollections
                });
              }

              proxy.writeFragment({
                id: `Collection:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res',
                data: collection
              });
            }
          })
            .then(res => {
              console.log(res);
            })
            .catch(err => console.log(err))
        }
      >
        <span>
          <Eye width={18} height={18} strokeWidth={2} color={'#f98012'} />
        </span>
        <Trans>Follow</Trans>
      </Span>
    );
  }
};

const Span = styled.div<{ unfollow?: boolean }>`
  padding: 0px 10px;
  color: ${props =>
    props.unfollow
      ? props => props.theme.styles.colour.heroCollectionIcon
      : props.theme.styles.colour.heroCollectionIcon};
  height: 40px;
  font-weight: 600;
  font-size: 13px;
  line-height: 38px;
  cursor: pointer;
  text-align: center;
  border-radius: 100px;
  padding: 0 14px;
  &:hover {
    color: ${props =>
      props.unfollow
        ? props => props.theme.styles.colour.heroCollectionIcon
        : props.theme.styles.colour.base6};
    background: ${props =>
      props.unfollow ? '#1e1f241a' : props.theme.styles.colour.primary};
  }
  & span {
    display: inline-block;
    vertical-align: middle;
  }
  & svg {
    margin-right: 8px;
    vertical-align: sub;
    color: inherit !important;
  }
`;

export default compose(
  withJoinCollection,
  withLeaveCollection
)(Join);