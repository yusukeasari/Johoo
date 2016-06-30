<?php

$FOUND=false;

if(!empty($_GET['id'])){
	$json = file("../swfData/pitcomdb.json");
	$line=json_decode($json[0],true);
	foreach($line as $k=>$v){
		if($v["id"] == $_GET['id'] && strlen($_GET['id'])==6){
			$v["result"]="FOUND";
			echo "[[".json_encode($v)."],".'[{"ERROR":""},{"TOTAL":1}]]';
			$FOUND = true;
			break;
		}
	}

	if(!$FOUND){
		echo '[[],[{"ERROR":"NOTFOUND"}]]';
	}
}else if(!empty($_GET['n'])){
	$json = file("../swfData/pitcomdb.json");
	$line=json_decode($json[0],true);
	foreach($line as $k=>$v){
		if($v["num"] == $_GET['n']){
			$v["result"]="FOUND";
			echo "[".json_encode($v)."]";
			$FOUND = true;
			break;
		}
	}

	if(!$FOUND){
		echo '[{"ERROR":"NOTFOUND"}]';
	}
}else{
	$result = array();
	$json = file("../swfData/pitcomdb.json");
	$line=json_decode($json[0],true);
	foreach($line as $k => $v){
		$b1 = '';
		$b2 = '';
		foreach($_GET as $k2 => $v2){
			if($k2 == 'b1'){
				$b1 = $v2;
			}
			if($k2 == 'b2'){
				$b2 = $v2;
			}
		}
		if(!empty($b1) && !empty($b2) && preg_match("/".$b1."/", $v['b1']) && preg_match("/".$b2."/", $v['b2']) && $v['flg'] == 1){
			//print "パターン1:"."{$b1}/{$b2}:{$v['b1']}/{$v['b2']}/{$v['flg']}<br />";
			array_push($result,$v);
		}else if(!empty($b1) && empty($b2) && preg_match("/".$b1."/", $v['b1']) && $v['flg'] == 1){
			//print "パターン2:"."{$b1}/{$v['b1']}/{$v['flg']}<br />";
			array_push($result,$v);
		}else if(!empty($b2) && empty($b1) && preg_match("/".$b2."/", $v['b2']) && $v['flg'] == 1){
			//print "パターン3:"."{$b2}/{$v['b2']}/{$v['flg']}<br />";
			array_push($result,$v);
		}
	}
	$count = count($result);

	if (count($result) > 300){
		echo '[[],[{"ERROR":"TOOMUCHRESULT"},{"TOTAL":'.$count.'}]]';
		exit;
	}
	if(!empty($_GET['page'])){
		$result = array_splice($result, ($_GET['page']-1)*10,10);
	}else{
		$result = array_splice($result, 0,10);
	}

	if(count($result) > 0){
		echo '['.json_encode($result).',[{"ERROR":""},{"TOTAL":'.$count.'}]]';
	}else if($_GET['id'] == '' && @$_GET['b1'] == '' && @$_GET['b2'] == ''){
		echo '[[],[{"ERROR":"NOWORD"},{"TOTAL":0}]]';
	}else{
		echo '[[],[{"ERROR":"NOTFOUND"},{"TOTAL":0}]]';
	}
}
