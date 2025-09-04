@echo off
setlocal enabledelayedexpansion
rem Uses ImageMagick

set input_path=C:\steam_ssd\steamapps\common\Factorio\data\space-age\graphics\entity\lavaslug\

call :process_file "%input_path%lavaslug-head-1.png" "lavaslug-head-mask-1.png"
call :process_file "%input_path%lavaslug-head-2.png" "lavaslug-head-mask-2.png"
call :process_file "%input_path%lavaslug-head-3.png" "lavaslug-head-mask-3.png"
call :process_file "%input_path%lavaslug-head-4.png" "lavaslug-head-mask-4.png"
call :process_file "%input_path%lavaslug-head-5.png" "lavaslug-head-mask-5.png"

call :process_file "%input_path%lavaslug-segment-1.png" "lavaslug-segment-mask-1.png"
call :process_file "%input_path%lavaslug-segment-2.png" "lavaslug-segment-mask-2.png"
call :process_file "%input_path%lavaslug-segment-3.png" "lavaslug-segment-mask-3.png"
call :process_file "%input_path%lavaslug-segment-4.png" "lavaslug-segment-mask-4.png"
call :process_file "%input_path%lavaslug-segment-5.png" "lavaslug-segment-mask-5.png"

call :process_file "%input_path%lavaslug-tail-1.png" "lavaslug-tail-mask-1.png"
call :process_file "%input_path%lavaslug-tail-2.png" "lavaslug-tail-mask-2.png"
call :process_file "%input_path%lavaslug-tail-3.png" "lavaslug-tail-mask-3.png"
call :process_file "%input_path%lavaslug-tail-4.png" "lavaslug-tail-mask-4.png"
call :process_file "%input_path%lavaslug-tail-5.png" "lavaslug-tail-mask-5.png"
call :process_file "%input_path%lavaslug-tail-6.png" "lavaslug-tail-mask-6.png"

del tmp0.png tmp1.png tmp2.png
exit /B 0

:process_file
	echo %2
	
	magick.exe %1 ^
	( -clone 0 -colorspace CMYK -channel Y -separate +channel -negate ) ^
	( -clone 0 -colorspace HSL -channel G -separate +channel -negate ) ^
	-delete 0 ^
	-define compose:args=70,30 -compose blend -composite ^
	-brightness-contrast -35x80 -colorspace Gray ^
	tmp0.png
	
	magick.exe %1 ^
	-alpha extract -colorspace Gray ^
	tmp1.png

	magick.exe tmp0.png tmp1.png ^
	-compose Multiply -composite ^
	tmp2.png

	magick.exe %1 tmp2.png ^
	-compose CopyAlpha -composite ^
	%2
exit /B 0
