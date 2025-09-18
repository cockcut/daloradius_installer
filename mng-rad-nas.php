<?php
/*
 *********************************************************************************************************
 * daloRADIUS - RADIUS Web Platform
 * Copyright (C) 2007 - Liran Tal <liran@enginx.com> All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *********************************************************************************************************
 *
 * Authors:	Liran Tal <liran@enginx.com>
 *
 *********************************************************************************************************
 */

    include ("library/checklogin.php");
    $operator = $_SESSION['operator_user'];
        
	include_once('library/config_read.php');
    $log = "visited page: ";

// RADIUS 재시작 로직 추가
if (isset($_POST['restart_radius'])) {
    $command = "sudo /usr/bin/systemctl restart radiusd.service 2>&1";
    $return_code = 1; // 실패로 초기화
    $output = array();

    exec($command, $output, $return_code);

    if ($return_code === 0) {
        $message = "RADIUS 데몬이 성공적으로 재시작되었습니다. 🥳";
    } else {
        $error_message = implode("\n", $output);
        $message = "RADIUS 데몬 재시작 실패. 😥<br>오류 코드: " . $return_code . "<br>오류 메시지: <pre>" . $error_message . "</pre>";
        
        // "sudo: a password is required" 오류 메시지가 포함된 경우
        if (strpos($error_message, 'sudo: a password is required') !== false) {
            $message .= "<br><br><b>💡 문제 해결 방법:</b><br>";
            $message .= "이 문제는 웹 서버가 sudo 명령을 실행할 권한이 없기 때문입니다. 아래 명령어로 sudoers 파일을 수정하여 비밀번호 없이 실행할 수 있도록 허용해야 합니다.";
            $message .= "<br><br><code><b>1. sudo visudo 를 실행합니다.</b></code><br>";
            $message .= "<code><b>2. 파일 맨 아래에 다음 줄을 추가한후 브라우저를 refresh 하세요.:</b></code><br>";
            $message .= "<code><b>apache ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart radiusd.service</b></code><br>";
        }
    }
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>daloRADIUS</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="css/1.css" type="text/css" media="screen,projection" />
</head>
<script src="library/javascript/pages_common.js" type="text/javascript"></script>
<?php
	include ("menu-mng-rad-nas.php");
?>
		<div id="contentnorightbar">
		
				<h2 id="Intro"><a href="#" onclick="javascript:toggleShowDiv('helpPage')"><?php echo t('Intro','mngradnas.php') ?>
				<h144>&#x2754;</h144></a></h2>
				
				<div id="helpPage" style="display:none;visibility:visible" >				
					<?php echo t('helpPage','mngradnas') ?>
					<br/>
				</div>
				<br/>
<b>※ NAS 추가후 반드시 RADUIS Restart 버튼을 클릭하여 Radius 서비스를 재시작하세요.</b>
<?php
	// 재시작 메시지 표시
	if (isset($message)) {
		echo "<div style='background-color:#dff0d8; color:#3c763d; border:1px solid #d6e9c6; padding:15px; margin-bottom:20px; border-radius:4px;'>";
		echo $message;
		echo "</div>";
	}
?>

<?php
	include('include/config/logging.php');
?>

		</div>

		<div id="footer">

<?php
	include 'page-footer.php';
?>


		</div>

</div>
</div>


</body>
</html>
