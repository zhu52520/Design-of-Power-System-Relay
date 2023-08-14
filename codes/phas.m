function V_ = phas(domain,Vi,f,sample_rate)
w = 2*pi*f;
num = floor(sample_rate/f);
V_ = zeros(length(Vi)-num,1);

for i=1:(length(Vi)-num)
    t = domain(i:i+num);
    V = Vi(i:i+num);
    temp1 = trapz(t,(V.*cos(w*t)))/trapz(t,cos(w*t).*cos(w*t));
    temp2 = trapz(t,(V.*sin(w*t)))/trapz(t,sin(w*t).*sin(w*t));
    V_(i) = temp1-1j*temp2;
end