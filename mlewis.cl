typedef float4 point;
typedef float4 vector;
typedef float4 color;
typedef float4 sphere;


vector
Bounce( vector in, vector n )
{
	vector out = in - n*(vector)( 2.*dot(in.xyz, n.xyz) );
	out.w = 0.;
	return out;
}

vector
BounceSphere( point p, vector v, sphere s )
{
	vector n;
	n.xyz = fast_normalize( p.xyz - s.xyz );
	n.w = 0.;
	return Bounce( v, n );
}

vector
BouncePyramid( point p, vector in)
{
	vector n;
	n.xyz = (fast_normalize( (float4)(1.0, -1.0, -1.0, 0.0))).xyz;
	n.w = 0.;
	return Bounce( in, n );
}

bool
IsInsideSphere( point p, sphere s )
{
	float r = fast_length( p.xyz - s.xyz );
	return  ( r < s.w );
}

bool
IsInsidePyramid( point p)
{
	bool plane1 =  p.x  - p.y - p.z > 700;	//plane 1
	bool plane2 = p.z > 0.	;							//plane 2
	bool plane3 = p.x < 800.;					//plane 3
	bool plane4 = (p.y + 500.)  > 0.	;					//plane 4
	return plane1&&plane2&&plane3&&plane4;
}

kernel
void
Particle( global point *dPobj, global vector *dVel, global color *dCobj )
{
	const float4 G       = (float4) ( 0., -9.8, 0., 0. );
	const float  DT      = 0.1;
	const sphere Sphere1 = (sphere)( -800., -500., 0.,  600. );
	int gid = get_global_id( 0 );

	point  p = dPobj[gid];
	vector v = dVel[gid];
	color col = dCobj[gid];

	point  pp = p + v*DT + .5*DT*DT*G;
	vector vp = v + G*DT;
	pp.w = 1.;
	vp.w = 0.;
	
	if( IsInsidePyramid( pp ) )
	{
		vp = BouncePyramid( p, v );
		pp = p + vp*DT + .5*DT*DT*G;
		col += (float4)(-0.5, 0.5, 0.5, 0.0);
		if (col.y>1.0)
			col.y = 0.1;
		if (col.z>1.0)
			col.z = 0.1;
		
	}
	
	if( IsInsideSphere( pp, Sphere1 ) )
	{
		vp = BounceSphere( p, v, Sphere1 );
		pp = p + vp*DT + .5*DT*DT*G;
		col += (float4)(-0.5, 0.0, 0.5, 0.0);
		if (col.x>1.0)
			col.x = 0.1;
		if (col.z<0.3)
			col.z = 1.0;
	}
	
	

	dPobj[gid] = pp;
	dVel[gid]  = vp;
	dCobj[gid] = col;
}
