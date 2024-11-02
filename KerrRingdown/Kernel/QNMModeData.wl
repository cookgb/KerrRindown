(* ::Package:: *)

(* ::Chapter:: *)
(*QNM Mode Data Routines Package*)


(* ::Section::Closed:: *)
(*Begin QNMModeData Package*)


BeginPackage["KerrRingdown`"]


(* ::Section::Closed:: *)
(*Documentation of External Functions*)


(* ::Subsection::Closed:: *)
(*QNM Mode data routines*)


HDF5QNMDir::usage=
"HDF5QNMDir[directory] "<>
"Set the directory storing the HDF5 data files which contain the "<>
"Quasinormal Mode data files.  The supplied directory should end in a \"/\""


(* ::Subsection::Closed:: *)
(*Reserved Globals*)


Protect[PhaseChoice]


Begin["`Private`"]


Protect[KRF\[Omega],KRFYS,KRFYSlen];


(* ::Section::Closed:: *)
(*QNM Mode Data Routines*)


HDF5QNMdir="";
HDF5QNMDir[dir_]:=HDF5QNMdir=dir;


ReadKerrQNM[qnm_List]:=Module[{nname,mnamea,mname,qnmname},
If[Head[qnm[[3]]]==List,
If[Length[qnm[[3]]]!=2 &&Not[IntegerQ[qnm[[3]]]],Print["Improper overtone index ",qnm];Abort[]];
nname=If[qnm[[3,1]]<10,"0"<>ToString[qnm[[3,1]]],ToString[qnm[[3,1]]]],
Null[],
nname=If[qnm[[3]]<10,"0"<>ToString[qnm[[3]]],ToString[qnm[[3]]]]
];
If[Not[IntegerQ[qnm[[2]]]],Print["Improper m index"];Abort[]];
mnamea=If[Abs[qnm[[2]]]<10,"0"<>ToString[Abs[qnm[[2]]]],ToString[Abs[qnm[[2]]]]];
mname=If[qnm[[2]]<0,"-"<>mnamea,"+"<>mnamea];
If[Not[IntegerQ[qnm[[1]]]],Print["Improper l index"];Abort[]];
qnmname = StringReplace[ToString[qnm]," "->""];
Import[HDF5QNMdir<>"KerrQNM_"<>nname<>".h5",{"HDF5","Datasets",{"/n"<>nname<>"/m"<>mname<>"/"<>qnmname}}]
]


GetQNMData[a_?NumberQ,qnm_List]:=Module[{rawdat,index,range,subdat,interpdat,pos,ai},
Off[Import::dataset];
rawdat=ReadKerrQNM[qnm];
On[Import::dataset];
If[rawdat==$Failed,Return[$Failed]];
(* Find range containing a *)
pos = SequencePosition[Flatten[Take[rawdat,{1,-1},{1}],1],{x_/;x>=a},1];
index=Min[Length[rawdat]-1,Max[3,If[Length[pos]>0,pos[[1,1]],Infinity,Infinity]]];
subdat=Interpolation[Function[x,{x[[1]],Drop[x,1]}]/@Drop[Take[rawdat,{index-2,index+1}],0,{4,8}]];
ai=a;
If[$MinPrecision>0,subdat=SetPrecision[subdat,$MinPrecision];ai=SetPrecision[ai,$MinPrecision]];
interpdat=Function[x,x[[1]]+I x[[2]]]/@Partition[subdat[ai],2];
{interpdat[[1]],Drop[interpdat,1]}
]


Options[SetModeData]={PhaseChoice->"SL-C"};
SetModeData[a_?NumberQ,qnmp_List,qnmm_List,opts:OptionsPattern[]]:=
Module[{s=-2,qnm,i,j,l,m,n,dat,lp,pc=OptionValue[PhaseChoice],index,phase},
   Unprotect[KRF\[Omega],KRFYS,KRFYSlen];
   Clear[KRF\[Omega],KRFYS,KRFYSlen]; (* Clear the package globals before setting *)
   KRF\[Omega][l1_,m1_,n1_]:=0;KRFYS[l2_,l1_,m1_,n1_]:=0;KRFYSlen[l1_,m1_,n1_]:=0;
   qnm=DeleteDuplicates[Join[qnmp,Function[x,{x[[1]],-x[[2]],x[[3]]}]/@qnmm]];
   For[i=1,i<=Length[qnm],++i,
      l=qnm[[i,1]];m=qnm[[i,2]];n=qnm[[i,3]];
      dat=GetQNMData[a,qnm[[i]]]; If[dat==$Failed,Abort[]];
      KRF\[Omega][l,m,n]=dat[[1]];
      KRFYSlen[l,m,n]=Length[dat[[2]]];
      Switch[pc,
        (* Continuous Spherical Limit *)"SL-C",
        For[lp=Max[Abs[s],Abs[m]];j=1,j<=Length[dat[[2]]],++lp;++j,KRFYS[lp,l,m,n]=dat[[2,j]]],
        (* Cook-Zalutskiy Spherical Limit *)"CZ-SL",
        index=l-Max[Abs[m],2]+1;
		phase=Exp[-I Arg[dat[[2,index]]]];
		For[lp=Max[Abs[s],Abs[m]];j=1,j<=Length[dat[[2]]],++lp;++j,KRFYS[lp,l,m,n]=dat[[2,j]]*phase],
		_,Print["Unknown Phase Choice: Abort"];Abort[]
      ]
   ];
   Protect[KRF\[Omega],KRFYS,KRFYSlen];
]


(* ::Section::Closed:: *)
(*End of QNMModeData Package*)


End[] (* `Private` *)


EndPackage[]
