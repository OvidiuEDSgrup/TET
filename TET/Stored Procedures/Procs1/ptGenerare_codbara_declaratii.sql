--***
/**	proc. generare codbara decl.	*/
Create procedure  ptGenerare_codbara_declaratii (@cTerm char(8))
As
delete from par where Tip_parametru='PS' and Parametru='GCODBDECL'
insert into par (Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica)
select 'PS', 'GCODBDECL', 'GCODBDECL', 1, 0, ''
exec ptGenerare_codbara_OP @cTerm 
delete from par where Tip_parametru='PS' and Parametru='GCODBDECL'
return
