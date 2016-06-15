--***
create function  fGrpMed (@nGrup int, @cGestiune char(20), @cCod char(20), @cCont char(20))
returns varchar(700)
as begin

return (case @nGrup 
 when 1 then @cGestiune+@cCod+@cCont
 when 2 then @cCod+@cCont
 when 3 then @cCod
 else @cGestiune+@cCod 
end)
 
end
