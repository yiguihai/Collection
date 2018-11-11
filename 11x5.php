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
<form action="" method="POST" autocomplete="on">
投入金额: <input type="number" name="Money" required><br>
投注次数: <input type="number" name="Quantity" required><br>
<input type="submit" value="计算">
</form>

<!--<p>点击"提交"按钮，表单数据将被发送到服务器上的“demo-form.php”。</p>-->
EOF;
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
$x=0;
$coin = $_POST['Money'];
$max = $_POST['Quantity'];

for($i = 0; $i < $max; $i++) {
  switch ($i):
    case 0:
        $money[]=$coin;
        break;
    case 1:
        $money[]=$coin*2;
        break;
    case 2:
        $money[]=$coin*3;
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

foreach ($money as $value)
{
  $x=$x+1;
  echo "<tr><td>$x</td><td>$value</td></tr>";
}
echo "<tr><th>预备金额</th><td>".end($money)."</td></tr></table>";
//echo "<tr><th>总金额</th><td>".array_sum($money)."</td></tr></table>";

}
?>
</body>
</html>