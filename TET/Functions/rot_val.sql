--***
create function  rot_val (@valoare float, @nr_zecimale int) returns float 
as begin 
 return round(convert(decimal(17,5), @valoare), @nr_zecimale) 
end 
