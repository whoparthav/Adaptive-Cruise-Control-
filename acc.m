% Initialize the Arduino UNO
x = arduino('COM3','Uno','Libraries',{'Ultrasonic','ExampleLCD/LCDAddon'},'ForceBuildOn',true);
ultrasonicsensor = ultrasonic(x,'D12','D8','OutputFormat','double');
lcd = addon(x,'ExampleLCD/LCDAddon','RegisterSelectPin','D7','EnablePin','D6','DataPins',{'D5','D4','D3','D2'});
initializeLCD(lcd); % initialize LCD 

clearLCD(lcd); % clear the LCD 
printLCD(lcd,char("Welcome")); % print Welcome message on the LCD screen
pause(2); % take a pause of 2 seconds before clearing the LCD
clearLCD(lcd); % clear LCD screen
printLCD(lcd,char("Group AJV")); % print the message Group AJV (A- Aarati, J-Jaydip, V-Vidhi)
pause(2); % take a pause of 2 seconds
clearLCD(lcd); % clear LCD screen

% Give initial values to ACC system
set_speed_value=0; % set 0 value to cruise control button
adaptive_cruise_control_speed=0; % set 0 value to adaptive cruise control button
cancel_button=0; % set 0 value to cancel button
speed_increase_button=0; % set 0 value to increase speed button 
speed_decrease_button=0; % set 0 value to decrease speed button
speed_counter=0;          % set speed counter to 0 so that speed increases from 0 value
input_value=0;          % check which button is pressed that is set speed button, adaptive cruise mode, increase speed, decrease speed or cancel button

%% Implementation of logic for ACC system
while 1  % executing a continous loop until program is canceled 
    set_speed_value = readVoltage(x,'A3');           % Read set_Speed button which is at Analog Pin 3
    speed_increase_button = readDigitalPin(x,'D13');  % Read increase_Speed button which is at Digital pin 13
    speed_decrease_button = readVoltage(x,'A4');      % Read decrease_speed button which is at Analog pin 4
    adaptive_cruise_control_speed = readDigitalPin(x,'D9');   % Read adaptive_speed button which is at Digital pin 9
    cancel_button = readDigitalPin(x,'D11');          % Read cancel button which is at Digital pin 11
    distance = readDistance(ultrasonicsensor); % Read ultrasonic sensor value

    if input_value==0  % when cruise control button is OFF
    if speed_increase_button==1       % increase speed button is pressed
        speed_counter=speed_counter+1;         % speed variable is assigned new value that is speed + 1 
    elseif speed_decrease_button==1   % decrease speed button is pressed
        speed_counter=speed_counter-1;         % speed variable is assigned new value that is speed - 1
    else
        speed_counter=speed_counter-1;         % when increase speed button is released then speed variable is assigned new value that is speed - 1
    end
    
    elseif input_value==1 % when cruise control button is ON
        speed_counter=speed_counter; % speed is kept constant that can be set using increase speed or decrease speed button
        
    elseif input_value==2 % adaptive cruise control button is ON
        if distance <  0.5 % when object is detected at a distance less than 0.5 
            speed_counter=speed_counter-1; % decrease the speed by the gap of 1 
        else
            speed_counter=speed_counter+1; % else increase the speed until speed reaches the set speed that is speed limit
        end
        if speed_counter>spdlim % if speed increases than speed limit
            speed_counter=spdlim; % keep the speed constant at the set speed value
        end
    end
    
    if set_speed_value > 4            % the set_speed button is pressed
        input_value=1;
    elseif adaptive_cruise_control_speed==1     %the adaptive_speed button is pressed
        input_value=2;
        spdlim=speed_counter;
    elseif cancel_button==1             % the cancel button is pressed
        input_value=0;
    elseif speed_increase_button==1 && input_value~=2
        speed_counter=speed_counter+1;
    elseif speed_decrease_button > 4 && input_value~=2
        speed_counter=speed_counter-1;
    end
    
    if speed_counter<0 % incase speed value is less than 0
        speed_counter=0; % set the speed value to 0 as speed cannot be negative
    end
        
    % Display the speed on LCD screen
    if input_value==1 % when cruise control button is pressed
        printLCD(lcd,'Cruise Mode '); % print "Cruise Mode" on LCD screen and keep the LCD constant
        printLCD(lcd, char("Speed:" + speed_counter + " km/h" )); % print the speed value below "Cruise Mode" on the LCD screen with the unit km/h
        pause(0.5);  % take a pause for 0.5 seconds
        
    elseif input_value==2 % when adaptive cruise control button is pressed
        printLCD(lcd,'ACC Mode '); % print "ACC Mode" on LCD screen 
        printLCD(lcd, char("Speed: " + speed_counter + " km/h")); % print the speed value below "ACC Mode" on the LCD screen with the unit km/h
        % logic to blink LCD screen when adaptive cruise control button is ON
        pause(0.7); % take a pause for 0.7 seconds
        clearLCD(lcd);  % clear LCD screen
        pause(0.7); % again take a pause of 0.7 seconds
        
    else
    printLCD(lcd,'Speed: '); % print speed value on the LCD screen in normal mode
    printLCD(lcd, char( speed_counter + " km/h")); % print the speed value along with km/h unit
    pause(0.5); % take a pause for 0.5 seconds
    end
end
