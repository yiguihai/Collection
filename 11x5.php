<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0, initial-scale=1.0, user-scalable=no">
<title>投注盈利计算</title>
<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}
</style>
</head>
<body>
<?php 
echo <<<EOF
<form action="" method="GET" autocomplete="on">
投注金额: <input type="number" name="Money" required><br>
下注次数: <input type="number" name="Quantity" required><br>
<input type="submit" value="计算">
</form>
EOF;

$x=0;
$coin = $_GET['Money'];
$max = $_GET['Quantity'];

if ($_SERVER['REQUEST_METHOD'] == 'GET' && $coin && $max) {
  for($i = 0; $i < $max; $i++) {
    switch ($i):
      case 0:
          $money[]=$coin;
          break;
      case 1:
          $money[]=$coin*2;
          break;
      case 2:
          $money[]=$coin*4;
          break;
      default:
          $money[]=end($money)*2;
    endswitch;
  }

echo <<<EOF
<table>
  <caption>下注计算结果</caption>
  <tr>
    <th>次数</th>
    <th>金额</th>
  </tr>
EOF;

  foreach ($money as $value) {
    $x=$x+1;
    echo "<tr><td>$x</td><td>$value</td></tr>";
  }
  echo "<tr><th>预备金总额</th><td>".array_sum($money)."</td></tr></table>";
}
?>
</body>
</html>