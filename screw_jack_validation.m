% A PROGRAM TO DESIGN A SCREW JACK (FINAL FULL VERSION)

clc;
clear;

PI = 3.1415;

fprintf('\nDESIGN INPUT DATA BY CONSUMER\n');

w = input('\nLoad to be lifted (kN) = ');
lift = input('\nLift required (mm) = ');

% Convert load to N
w = w * 1000;

fprintf('\nDESIGN INPUT DATA BY DESIGNER \n');

fprintf('\nSelect material for the screw :\n');
fprintf('\nAlloy Steel - Yield strength = 690 N/mm^2\n');
fprintf('Alloy Steel provides great fatigue resistance and surface hardness. Used in heavy screw jack applications.\n');
fprintf('\nMedium Carbon Steel - Yield strength = 350 N/mm^2\n');
fprintf('Medium Carbon Steel provides good strength at a reasonable cost and can withstand moderate to high loads.\n');
fprintf('\nHigh Tensile Alloy Steel - Yield strength = 850 N/mm^2\n')
fprintf('High Tensile Alloy Steel provides extreme strength but is very expensive. Only used in extremely high loading conditions.\n');
sigmascy = input('\n Yield strength of the screw material (N/mm^2) = ');

fprintf('\nSelect material for the nut :\n');
fprintf('Phosphor Bronze - Yield strength = 210 N/mm^2\n');
fprintf('Phosphor bronze is considered the best material for nut due to its conformability but is expensive.\n');
fprintf('\nGun Metal - Yield strength = 190 N/mm^2\n');
fprintf('Gun Metal is the most commonly used material in power screws.\n');
fprintf('\nCast Iron - Yield strength = 170 N/mm^2\n');
fprintf('Cast Iron is economical but not suitable for heavy duty applications due to its brittle nature.\n');
sigmanuty = input('\n Yield strength of the nut material (N/mm^2) = '); 

fos = input('\nFactor of safety = ');
mu = input('\nCoefficient of friction = ');

% Input Validation
if w <= 0
    error('Invalid Input: Load must be greater than 0 kN');
end

if lift <= 0
    error('Invalid Input: Lift must be greater than 0 mm');
end

if lift < 0
    error('lift should not be negative.\n');
end

if sigmascy <= 0
    error('Invalid Input: Screw material strength must be greater than 0');
end

if sigmanuty <= 0
    error('Invalid Input: Nut material strength must be greater than 0');
end

if fos <= 0
    error('Invalid Input: Factor of safety must be greater than 0');
end

if mu <= 0 || mu >= 1
    error('Invalid Input: Coefficient of friction must be between 0 and 1');
end

% Thread selection
fprintf('\nSelect thread type:\n');
fprintf('1. Square Thread\n');
fprintf('2. Trapezoidal Thread\n');
fprintf('3. V-Thread\n');
fprintf('4. Buttress Thread\n');
thread_type = input('Enter choice = ');

% Thread angle
switch thread_type
    case 1
        theta = 0;
    case 2
        theta = 29;
    case 3
        theta = 60;
    case 4
        theta = 45;
    otherwise
        error('Invalid thread type');
end

theta = deg2rad(theta/2);

% Permissible stress
sigmad = sigmascy / fos;

% Initial guess
d1 = ceil(sqrt((4*w)/(PI*sigmad)));
p = 5;

while true

    if d1 > 300
        error('Design not safe even at large diameter');
    end

    d2 = d1 - p;

    % Direct stress
    sigm = (4*w)/(PI*d2^2);

    if sigm > sigmad
        d1 = major_dia(d1);
        p = select_pitch(p, d1);
        continue;
    end

    d = (d1 + d2)/2;

    alpha = atan(p/(PI*d));

    % Effective friction
    mu_eff = mu / cos(theta);
    phi = atan(mu_eff);

    % Self-locking check
    if alpha > phi
        self_locking = false;
        d1 = major_dia(d1);
        p = select_pitch(p, d1);
        continue;
    else
        self_locking = true;
    end

    % Torque
    ts = w*d*tan(alpha + phi)/2;

    % Collar
    D1 = fix(1.6*d1 + 1);
    D2 = fix(0.5*d1 + 1);
    DC = (2/3)*((D1^3 - D2^3)/(D1^2 - D2^2));

    muc = 0.15;
    tc = 0.5*muc*w*DC;

    tr = ts + tc;

    % Handle
    sigma_allow = 150;
    dr = ((32*tr)/(PI*sigma_allow))^(1/3);
    dr = fix(dr + 2);

    h = 2*dr;

    lever_length = tr/400;
    lever_length = 10*fix((lever_length+5)/10) + 100;

    % Shear stress
    tau = (16*ts)/(PI*d2^3);

    % Buckling
    lscrew = lift + h;
    a = 1.95/25000;
    k = 0.25*d2;

    sigmac = (4*w/(PI*d2^2))*(1 + a*(lscrew/k)^2);

    % Bending
    moment = w*5;
    sigmab = (32*moment)/(PI*d2^3);

    sigma_combined = sigmac + sigmab;

    sigmamax = 0.5*(sigma_combined + sqrt(sigma_combined^2 + 4*tau^2));

    fos_calc = sigmascy / sigmamax;

    if fos_calc < fos
        d1 = major_dia(d1);
        p = select_pitch(p, d1);
        continue;
    end

    % Nut design
    n = (4*w)/(PI*(d1^2 - d2^2)*12);
    n = fix(n+1);

    h1 = n*p;

    if h1 < 2*d1
        h1 = 2*d1;
        n = fix(h1/p);
        h1 = n*p;
    end

    tau = w/(PI*d1*p*n);

    while tau > 25
        n = n + 1;
        tau = w/(PI*d1*p*n);
    end

    h1 = n*p;

    % Nut dimensions
    d3 = fix(1.5*d1);
    d4 = fix(1.5*d3);
    tn = fix(d3/3);

    % Body
    d5 = 10*fix((1.5*d4)/10);
    d6 = 4*d5;

    t1 = fix(0.3*d1);
    t2 = 2*t1;

    height = lift + 25;

    break;
end

% ================= REPORT =================

fprintf('\n\nDESIGN REPORT\n');

% Material output
if sigmascy == 690
    fprintf('\nMaterial used for screw is Alloy Steel.');
elseif sigmascy == 350
    fprintf('\nMaterial used for screw is Medium Carbon Steel.');
elseif sigmascy == 850
    fprintf('\nMaterial used for screw is High Tensile Alloy Steel.');
end

if sigmanuty == 210
    fprintf('\nMaterial used for nut is Phosphor Bronze.');
elseif sigmanuty == 190
    fprintf('\nMaterial used for nut is Gun Metal.');
elseif sigmanuty == 170
    fprintf('\nMaterial used for nut is Cast Iron.');
end

fprintf('\nMajor Diameter of the Screw = %.2f mm', d1);
fprintf('\nMinor Diameter of the Screw = %.2f mm', d2);
fprintf('\nMean Diameter of the Screw = %.2f mm', d);
fprintf('\nPitch of the Screw = %.2f mm', p);

fprintf('\nScrew Head Diameter = %.2f mm', D1);
fprintf('\nMinor Diameter of the Collar = %.2f mm', D2);

fprintf('\nDiameter of the Handle Bar = %.2f mm', dr);
fprintf('\nHeight of the Screw Head = %.2f mm', h);
fprintf('\nLength of the Handle Bar = %.2f mm', lever_length);

fprintf('\nTop Diameter of the Nut = %.2f mm', d4);
fprintf('\nOutside Diameter of the Nut = %.2f mm', d3);
fprintf('\nThickness of the Nut = %.2f mm', tn);

fprintf('\nType of threads used = ');
if thread_type==1
    fprintf('Square threads');
elseif thread_type==2
    fprintf('Trapezoidal threads');
elseif thread_type==3
    fprintf('V-threads');
else
    fprintf('Buttress threads');
end

fprintf('\nNumber of Threads = %.2f', n);
fprintf('\nHeight of the Nut = %.2f mm', h1);

fprintf('\nTop Diameter of the Body = %.2f mm', d5);
fprintf('\nBase Diameter of the Body = %.2f mm', d6);
fprintf('\nHeight of the Body = %.2f mm', height);

fprintf('\nThickness of the Body = %.2f mm', t1);
fprintf('\nThickness of the Body at the Base = %.2f mm', t2);

% SELF LOCKING
fprintf('\n\nSELF LOCKING CHECK:\n');
fprintf('\nHelix angle (alpha) = %.4f rad', alpha);
fprintf('\nFriction angle (phi) = %.4f rad', phi);
fprintf('\nCondition: phi > alpha');

if self_locking
    fprintf('\nResult: SELF-LOCKING (Safe)\n');
else
    fprintf('\nResult: NOT self-locking (Unsafe)\n');
end

fprintf('\nThread Behavior: ');
if thread_type == 1
    fprintf('Square thread → Minimum friction, high efficiency.\n');
elseif thread_type == 2
    fprintf('Trapezoidal thread → Moderate friction.\n');
elseif thread_type == 3
    fprintf('V-thread → High friction, self-locking but inefficient.\n');
else
    fprintf('Buttress thread → One-direction load application.\n');
end

% ================= FUNCTIONS =================

function dia = major_dia(dia)
    if dia < 32
        dia = dia + 2;
    elseif dia < 50
        dia = dia + 4;
    elseif dia < 100
        dia = dia + 5;
    elseif dia < 200
        dia = dia + 10;
    else
        dia = dia + 15;
    end
end

function pp = select_pitch(~, dia)
    if dia <= 28
        pp = 5;
    elseif dia <= 36
        pp = 6;
    elseif dia <= 44
        pp = 7;
    elseif dia <= 52
        pp = 8;
    elseif dia <= 60
        pp = 9;
    else
        pp = 10;
    end
end