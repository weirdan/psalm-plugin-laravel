<?php

namespace Psalm\LaravelPlugin\Handlers;

use Psalm\Plugin\EventHandler\AfterClassLikeVisitInterface;
use Psalm\Plugin\EventHandler\Event\AfterClassLikeVisitEvent;
use Psalm\Storage\ClassLikeStorage;
use Psalm\Storage\MethodStorage;
use Psalm\Storage\PropertyStorage;

use function array_intersect;
use function in_array;
use function strpos;
use function strtolower;

class SuppressHandler implements AfterClassLikeVisitInterface
{
    /**
     * @var array<string, list<class-string>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_CLASS = [
        'UnusedClass' => [
            \App\Console\Kernel::class,
            \App\Exceptions\Handler::class,
            \App\Http\Controllers\Controller::class,
            \App\Http\Kernel::class,
            \App\Http\Middleware\Authenticate::class,
            \App\Http\Middleware\TrustHosts::class,
            \App\Providers\AppServiceProvider::class,
            \App\Providers\AuthServiceProvider::class,
            \App\Providers\BroadcastServiceProvider::class,
            \App\Providers\EventServiceProvider::class,
        ],
    ];

    /**
     * @var array<string, array<class-string, list<string>>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_CLASS_METHOD = [
        'PossiblyUnusedMethod' => [
            \App\Http\Middleware\RedirectIfAuthenticated::class => ['handle'],
        ],
    ];

    /**
     * @var array<string, list<class-string>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_NAMESPACE = [
        'PropertyNotSetInConstructor' => [
            \App\Jobs::class,
        ],
        'PossiblyUnusedMethod' => [
            \App\Events::class,
            \App\Jobs::class,
        ],
    ];

    /**
     * @var array<string, array<class-string, list<string>>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_NAMESPACE_METHOD = [
        'PossiblyUnusedMethod' => [
            \App\Events::class => ['broadcastOn'],
            \App\Jobs::class => ['handle'],
            \App\Mail::class => ['__construct', 'build'],
            \App\Notifications::class => ['__construct', 'via', 'toMail', 'toArray'],
        ]
    ];

    /**
     * @var array<string, list<class-string>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_PARENT_CLASS = [
        'PropertyNotSetInConstructor' => [
            \Illuminate\Console\Command::class,
            \Illuminate\Foundation\Http\FormRequest::class,
            \Illuminate\Mail\Mailable::class,
            \Illuminate\Notifications\Notification::class,
        ],
    ];

    /**
     * @var array<string, array<class-string, list<string>>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_PARENT_CLASS_PROPERTY = [
        'NonInvariantDocblockPropertyType' => [
            \Illuminate\Console\Command::class => ['description'],
        ],
    ];

    /**
     * @var array<string, array<class-string>>
     * @psalm-suppress UndefinedClass
     */
    private const BY_USED_TRAITS = [
        'PropertyNotSetInConstructor' => [
            \Illuminate\Queue\InteractsWithQueue::class,
        ]
    ];

    public static function afterClassLikeVisit(AfterClassLikeVisitEvent $event)
    {
        $class = $event->getStorage();

        foreach (self::BY_CLASS as $issue => $class_names) {
            if (in_array($class->name, $class_names)) {
                self::suppress($issue, $class);
            }
        }

        foreach (self::BY_CLASS_METHOD as $issue => $method_by_class) {
            foreach ($method_by_class[$class->name] ?? [] as $method_name) {
                /**
                 * @psalm-suppress RedundantCast
                 * @psalm-suppress RedundantFunctionCall
                 */
                self::suppress($issue, $class->methods[strtolower($method_name)] ?? null);
            }
        }

        foreach (self::BY_NAMESPACE as $issue => $namespaces) {
            foreach ($namespaces as $namespace) {
                if (0 !== strpos($class->name, "$namespace\\")) {
                    continue;
                }

                self::suppress($issue, $class);
                break;
            }
        }

        foreach (self::BY_NAMESPACE_METHOD as $issue => $methods_by_namespaces) {
            foreach ($methods_by_namespaces as $namespace => $method_names) {
                if (0 !== strpos($class->name, "$namespace\\")) {
                    continue;
                }

                foreach ($method_names as $method_name) {
                    self::suppress($issue, $class->methods[strtolower($method_name)] ?? null);
                }
            }
        }

        foreach (self::BY_PARENT_CLASS as $issue => $parent_classes) {
            if (!array_intersect($class->parent_classes, $parent_classes)) {
                continue;
            }

            self::suppress($issue, $class);
        }

        foreach (self::BY_PARENT_CLASS_PROPERTY as $issue => $properties_by_parent_class) {
            foreach ($properties_by_parent_class as $parent_class => $property_names) {
                if (!in_array($parent_class, $class->parent_classes)) {
                    continue;
                }

                foreach ($property_names as $property_name) {
                    self::suppress($issue, $class->properties[$property_name] ?? null);
                }
            }
        }

        foreach (self::BY_USED_TRAITS as $issue => $used_traits) {
            if (!array_intersect($class->used_traits, $used_traits)) {
                continue;
            }

            self::suppress($issue, $class);
        }
    }

    /**
     * @param string $issue
     * @param ClassLikeStorage|PropertyStorage|MethodStorage|null $storage
     */
    private static function suppress(string $issue, $storage): void
    {
        if ($storage && !in_array($issue, $storage->suppressed_issues)) {
            $storage->suppressed_issues[] = $issue;
        }
    }
}
