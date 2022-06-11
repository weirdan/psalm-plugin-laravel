Feature: Taint Analysis
  Want to check that taint analysis works properly

  Background:
    Given I have the following config
      """
      <?xml version="1.0"?>
      <psalm errorLevel="2">
        <projectFiles>
          <directory name="."/>
          <ignoreFiles> <directory name="../../vendor"/> </ignoreFiles>
        </projectFiles>
        <plugins>
          <pluginClass class="Psalm\LaravelPlugin\Plugin"/>
        </plugins>
      </psalm>
      """
  @skip
  Scenario: input returns various types
    Given I have the following code
    """
    <?php declare(strict_types=1);

    namespace Tests\Psalm\LaravelPlugin\Sandbox;

    use \Illuminate\Http\Request;
    use Illuminate\Support\Facades\DB;

    function test(Request $request): void {
      $input = $request->input('foo', false);
      DB::raw($input);
    }
    """
    When I run Psalm with taint analysis
    Then I see these errors
      | Type         | Message                                                          |
      | TaintedInput | /Detected tainted sql in path: Illuminate\\Http\\Request::input/ |
