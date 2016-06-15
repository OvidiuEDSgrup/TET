--***
create function fDenTipContract(@Tip varchar(10)) returns varchar(50)
as begin
	return 
	(case @Tip 
		WHEN 'CB' THEN 'Contracte beneficiar' 
		WHEN 'CF' THEN 'Contracte furnizori' 
		WHEN 'CS' THEN 'Contracte servicii' 
		WHEN 'CA' THEN 'Comenzi aprovizionare' 
		WHEN 'CL' THEN 'Comenzi livrare' 
		-- din cate stiu nu vor mai exista aceste 2 tipuri de contract.
		-- cine stie sigur, sa stearga de tot aceste linii..
		--WHEN 'FP' THEN 'Facturi proforma'  
		--WHEN 'OF' THEN 'Oferte furnizori'
		else @tip
	end)
end
