Feature: Eloquent Relation types
  Illuminate\Database\Eloquent\Relations have type support

  Background:
    Given I have the following config
      """
      <?xml version="1.0"?>
      <psalm errorLevel="1" findUnusedCode="false">
        <projectFiles>
          <directory name="."/>
          <ignoreFiles> <directory name="../../vendor"/> </ignoreFiles>
        </projectFiles>
        <plugins>
          <pluginClass class="Psalm\LaravelPlugin\Plugin"/>
        </plugins>
      </psalm>
      """
    And I have the following code preamble
      """
      <?php declare(strict_types=1);
      namespace Tests\Psalm\LaravelPlugin\Sandbox;

      use \Illuminate\Database\Eloquent\Builder;
      use \Illuminate\Database\Eloquent\Model;
      use \Illuminate\Database\Eloquent\Collection;
      use \Illuminate\Database\Eloquent\Relations\HasOne;
      use \Illuminate\Database\Eloquent\Relations\BelongsTo;
      use \Illuminate\Database\Eloquent\Relations\BelongsToMany;
      use \Illuminate\Database\Eloquent\Relations\HasMany;
      use \Illuminate\Database\Eloquent\Relations\HasManyThrough;
      use \Illuminate\Database\Eloquent\Relations\HasOneThrough;
      use \Illuminate\Database\Eloquent\Relations\MorphMany;
      use \Illuminate\Database\Eloquent\Relations\MorphTo;
      use \Illuminate\Database\Eloquent\Relations\MorphToMany;

      use App\Models\Comment;
      use App\Models\Image;
      use App\Models\Mechanic;
      use App\Models\Phone;
      use App\Models\Post;
      use App\Models\Role;
      use App\Models\Tag;
      use App\Models\User;
      use App\Models\Video;
      """

  Scenario: Models can declare one to one relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return HasOne<Phone>
      */
      public function getPhoneRelationship(User $user): HasOne {
        return $user->phone();
      }

      /**
      * @psalm-return BelongsTo<User>
      */
      public function getUserRelationship(Phone $phone): BelongsTo {
        return $phone->user();
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare one to many relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return BelongsTo<Post>
      */
      public function getPostRelationship(Comment $comment): BelongsTo {
        return $comment->post();
      }

      /**
      * @psalm-return HasMany<Comment>
      */
      public function getCommentsRelationship(Post $post): HasMany {
        return $post->comments();
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare many to many relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return BelongsToMany<Role>
      */
      public function getRolesRelationship(User $user): BelongsToMany {
        return $user->roles();
      }

      /**
      * @psalm-return BelongsToMany<User>
      */
      public function getUserRelationship(Role $role): BelongsToMany {
        return $role->users();
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: BelongsToMany relationship can return null when the first method is used
    Given I have the following code
    """
    function testFirstBelongsToManyCanNull(User $user): bool {
      return $user->roles()->first() === null;
    }
    """
    When I run Psalm
    Then I see no errors

    Scenario: BelongsToMany relationship can return paginators
    Given I have the following code
    """
    /** @return \Illuminate\Pagination\LengthAwarePaginator<Role> */
    function testPaginate(User $user) {
      return $user->roles()->paginate();
    }

    /** @return \Illuminate\Pagination\Paginator<Role> */
    function testSimplePaginate(User $user) {
      return $user->roles()->simplePaginate();
    }

    /** @return \Illuminate\Pagination\CursorPaginator<Role> */
    function testCursorPaginate(User $user) {
      return $user->roles()->cursorPaginate();
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare has through relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return HasManyThrough<Mechanic>
      */
      public function getCarsAtMechanicRelationship(User $user): HasManyThrough {
        return $user->carsAtMechanic();
      }

      /**
      * @psalm-return HasOneThrough<User>
      */
      public function getCarsOwner(Mechanic $mechanic): HasOneThrough {
        return $mechanic->carOwner();
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: HasManyThrough relationship can return paginators
    Given I have the following code
    """
    /** @return \Illuminate\Pagination\LengthAwarePaginator<Mechanic> */
    function testPaginate(User $user) {
      return $user->carsAtMechanic()->paginate();
    }

    /** @return \Illuminate\Pagination\Paginator<Mechanic> */
    function testSimplePaginate(User $user) {
      return $user->carsAtMechanic()->simplePaginate();
    }

    /** @return \Illuminate\Pagination\CursorPaginator<Mechanic> */
    function testCursorPaginate(User $user) {
      return $user->carsAtMechanic()->cursorPaginate();
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare polymorphic relationships
    Given I have the following code
    """
    final class Repository
    {
      public function getPostsImageDynamicProperty(Post $post): Image {
        return $post->image;
      }

      /**
      * @todo: support for morphTo dynamic property
      * @psalm-return mixed
      */
      public function getImageableProperty(Image $image) {
        return $image->imageable;
      }

      /**
      * @todo: better support for morphTo relationships
      * @psalm-return MorphTo
      */
      public function getImageableRelationship(Image $image): MorphTo {
        return $image->imageable();
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare one to many polymorphic relationships
    Given I have the following code
    """
    final class Repository
    {
      /** @psalm-return MorphMany<Comment> */
      public function getCommentsRelation(Video $video): MorphMany {
        return $video->comments();
      }

      /** @psalm-return MorphMany<Comment> */
      public function getLatestCommentsRelation(Video $video): MorphMany {
        return $video->comments()->latest();
      }

      /** @psalm-return MorphMany<Comment> */
      public function getOldestCommentsRelation(Video $video): MorphMany {
        return $video->comments()->oldest();
      }

      /** @psalm-return Collection<int, Comment> */
      public function getComments(Video $video): Collection {
        return $video->comments;
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare many to many polymorphic relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return MorphToMany<Tag>
      */
      public function getTagsRelation(Post $post): MorphToMany {
        return $post->tags();
      }

      /**
      * @psalm-return Collection<int, Tag>
      */
      public function getTags(Post $post): Collection {
        return $post->tags;
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Polymorphic models can retrieve their inverse relation
    Given I have the following code
    """
    final class Repository
    {
      /**
      * todo: this should be a union of possible types...
      * @psalm-return mixed
      */
      public function getCommentable(Comment $comment) {
        return $comment->commentable;
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Models can declare inverse of many to many polymorphic relationships
    Given I have the following code
    """
    final class Repository
    {
      /**
      * @psalm-return MorphToMany<Post>
      */
      public function getPostsRelation(Tag $tag): MorphToMany {
        return $tag->posts();
      }

      /**
      * @psalm-return MorphToMany<Video>
      */
      public function getVideosRelation(Tag $tag): MorphToMany {
        return $tag->videos();
      }

      /**
      * @psalm-return Collection<int, Post>
      */
      public function getPosts(Tag $tag): Collection {
        return $tag->posts;
      }

      /**
      * @psalm-return Collection<int, Video>
      */
      public function getVideos(Tag $tag): Collection {
        return $tag->videos;
      }
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Relationships can be accessed via a property
    Given I have the following code
    """
    function testGetPhone(User $user): Phone {
      return $user->phone;
    }

    function testGetUser(Phone $phone): User {
      return $phone->user;
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Relationships can be filtered via dynamic property
    Given I have the following code
    """
    function testFilterRelationshipFromDynamicProperty(User $user): Phone {
      return $user->phone->where('active', 1)->firstOrFail();
    }
    """
    When I run Psalm
    Then I see no errors

  @skip
  Scenario: Relationships can be further constrained via method
    Given I have the following code
    """
    function testFilterRelationshipFromMethod(User $user): Phone {
      return $user->phone()->where('active', 1)->firstOrFail();
    }
    """
    When I run Psalm
    Then I see no errors

  @skip
  Scenario: Relationships return themselves when the underlying method returns a builder
    Given I have the following code
    """
    /**
    * @param HasOne<Phone> $relationship
    * @psalm-return HasOne<Phone>
    */
    function testRelationshipsReturnThemselvesInsteadOfBuilders(HasOne $relationship): HasOne {
      return $relationship->where('active', 1);
    }

    /**
    * @psalm-return BelongsTo<User>
    */
    function testAnother(Phone $phone): BelongsTo {
      return $phone->user()->where('active', 1);
    }
    """
    When I run Psalm
    Then I see no errors

  @skip
  Scenario: Relationships return themselves when the proxied method is a query builder method
    Given I have the following code
    """
    /**
    * @param HasOne<Phone> $relationship
    * @psalm-return HasOne<Phone>
    */
    function test(HasOne $relationship): HasOne {
      return $relationship->orderBy('id', 'ASC');
    }
    """
    When I run Psalm
    Then I see no errors

  Scenario: Calling first() on HasMany relationship returns nullable related Model
    Given I have the following code
    """
    function test(User $user): ?Role {
      return $user->roles()->first();
    }
    """
    When I run Psalm
    Then I see no errors
