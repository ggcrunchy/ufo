--[[
--
--
-- Voxel.h
--
--
#ifndef VOXEL_H
#define VOXEL_H

#include <list>
#include <vector>

namespace Voxel
{
	/// @brief Ordering in which to iterate volume
	enum Order {
		eXYZ,	///< x, y, z ordering
		eXZY,	///< x, z, y ordering
		eYXZ,	///< y, x, z ordering
		eYZX,	///< y, z, x ordering
		eZXY,	///< z, x, y ordering
		eZYX	///< z, y, x ordering
	};

	// Forward references
	struct StepInfo;
	class ColumnIter;
	class ColumnIterF;
	class ColumnIterR;
	class RowIter;
	class RowIterF;
	class RowIterR;
	class SpanIter;
	class SpanIterF;
	class SpanIterR;

	/// @brief Data base class
	class Data {
	protected:
		// Members
		float mD[3];///< Dimensions, in standard form

		// Lifetime
		Data (float dx, float dy, float dz);
		virtual ~Data (void) {}

		// Methods
		virtual StepInfo * EdgeC (bool bEnd, bool bReverse) = 0;
		virtual StepInfo * EdgeR (StepInfo * csi, bool bEnd, bool bReverse) = 0;
		virtual StepInfo * EdgeS (StepInfo * rsi, bool bEnd, bool bReverse) = 0;
		virtual void StepC (StepInfo * csi, bool bReverse, bool bDec) = 0;
		virtual void StepR (StepInfo * rsi, bool bReverse, bool bDec) = 0;
		virtual void StepS (StepInfo * ssi, bool bReverse, bool bDec) = 0;

		// Friendship
		friend class ColumnIter;
		friend class ColumnIterF;
		friend class ColumnIterR;
		friend class RowIter;
		friend class RowIterF;
		friend class RowIterR;
		friend class SpanIter;
		friend class SpanIterF;
		friend class SpanIterR;
	public:
		// Methods
		ColumnIterF begin (void);
		ColumnIterR rbegin (void);
		ColumnIterF end (void);
		ColumnIterR rend (void);
	};

	/// @brief Base iterator type
	class Iter {
	protected:
		// Members
		StepInfo * mSI;	///< Step info
		Data * mVD;	///< Voxel data

		// Lifetime
		Iter (StepInfo * si, Data * vd) : mSI(si), mVD(vd) {}
		virtual ~Iter (void);
	public:
		// Methods
		bool operator == (Iter const & v);
		bool operator != (Iter const & v);
	};

	/// @brief Base column iterator
	class ColumnIter : public Iter {
	protected:
		// Lifetime
		ColumnIter (StepInfo * si, Data * vd) : Iter(si, vd) {}
	public:
		// Methods
		int operator * (void);

		RowIterF begin (void);
		RowIterF end (void);
		RowIterR rbegin (void);
		RowIterR rend (void);

		virtual void operator ++ (void) = 0;
		virtual void operator -- (void) = 0;
	};

	/// @brief Forward column iterator
	class ColumnIterF : public ColumnIter {
	private:
		// Lifetime
		ColumnIterF (StepInfo * si, Data * vd) : ColumnIter(si, vd) {}

		// Friendship
		friend class Data;
	public:
		// Lifetime
		ColumnIterF (ColumnIterF const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};

	/// @brief Reverse column iterator
	class ColumnIterR : public ColumnIter {
	private:
		// Lifetime
		ColumnIterR (StepInfo * si, Data * vd) : ColumnIter(si, vd) {}

		// Friendship
		friend class Data;
	public:
		// Lifetime
		ColumnIterR (ColumnIterR const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};

	/// @brief Base row iterator
	class RowIter : public Iter {
	protected:
		// Lifetime
		RowIter (StepInfo * si, Data * vd) : Iter(si, vd) {}
	public:
		// Methods
		int operator * (void);

		SpanIterF begin (void);
		SpanIterF end (void);
		SpanIterR rbegin (void);
		SpanIterR rend (void);

		virtual void operator ++ (void) = 0;
		virtual void operator -- (void) = 0;
	};

	/// @brief Forward row iterator
	class RowIterF : public RowIter {
	private:
		// Lifetime
		RowIterF (StepInfo * si, Data * vd) : RowIter(si, vd) {}

		// Friendship
		friend class ColumnIter;
	public:
		// Lifetime
		RowIterF (RowIterF const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};

	/// @brief Reverse row iterator
	class RowIterR : public RowIter {
	private:
		// Lifetime
		RowIterR (StepInfo * si, Data * vd) : RowIter(si, vd) {}

		// Friendship
		friend class ColumnIter;
	public:
		// Lifetime
		RowIterR (RowIterR const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};

	/// @brief Base span iterator
	class SpanIter : public Iter {
	protected:
		// Lifetime
		SpanIter (StepInfo * si, Data * vd) : Iter(si, vd) {}
	public:
		// Methods
		int I (void);
		int F (void);

		virtual void operator ++ (void) = 0;
		virtual void operator -- (void) = 0;
	};

	/// @brief Forward span iterator
	class SpanIterF : public SpanIter {
	private:
		// Lifetime
		SpanIterF (StepInfo * si, Data * vd) : SpanIter(si, vd) {}

		// Friendship
		friend class RowIter;
	public:
		// Lifetime
		SpanIterF (SpanIterF const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};

	/// @brief Reverse span iterator
	class SpanIterR : public SpanIter {
	private:
		// Lifetime
		SpanIterR (StepInfo * si, Data * vd) : SpanIter(si, vd) {}

		// Friendship
		friend class RowIter;
	public:
		// Lifetime
		SpanIterR (SpanIterR const & vo);

		// Methods
		void operator ++ (void);
		void operator -- (void);
	};
}

#endif // VOXEL_H
--]]

--[[
--
--
-- VoxelImp.h
--
--
#ifndef VOXEL_IMP_H
#define VOXEL_IMP_H

namespace Voxel
{
	/// @brief Triple indices
	enum TripleIndex {
		eTX,///< x-index
		eTY,///< y-index
		eTZ	///< z-index
	};

	/// @brief Cell coordinates
	struct Cell	{
		// Members
		int m[3];	///< Cell offsets

		// Lifetime
		Cell (float v[3], float dx, float dy, float dz, float delta);

		// Methods
		void Distances (TripleIndex index, float center[3], float dim[3], float & dL, float & dG);
	};

	/// @brief Base step information type
	struct StepInfo {
		// Lifetime
		virtual ~StepInfo (void) {};

		// Methods
		virtual bool operator == (StepInfo & si) = 0;

		virtual StepInfo * Copy (void) = 0;

		virtual int M1 (void) = 0;
		virtual int M2 (void) { return M1(); }
	};
}

#endif // VOXEL_IMP_H
--]]

--[[
--
--
-- VoxelImp.cpp
--
--
#include "Voxel.h"
#include "VoxelImp.h"
#include <cmath>

namespace Voxel
{
	/// @brief Constructs a cell
	/// @param v Point in space
	/// @param dx Extent of space cell in x-direction
	/// @param dy Extent of space cell in y-direction
	/// @param dz Extent of space cell in z-direction
	/// @param delta Displacement on (x, y, z) line from point
	Cell::Cell (float v[3], float dx, float dy, float dz, float delta)
	{
		m[eTX] = int(ceilf((v[0] + delta) / dx - 0.5f));
		m[eTY] = int(ceilf((v[1] + delta) / dy - 0.5f));
		m[eTZ] = int(ceilf((v[2] + delta) / dz - 0.5f));
	}

	/// @brief Get the distances from the center to a pair of cell walls
	/// @param index Coordinate index
	/// @param center Sphere center
	/// @param dim Dimension array
	/// @param dL [out] Distance to wall with lesser coordinate
	/// @param dG [out] Distance to wall with greater coordinate
	void Cell::Distances (TripleIndex index, float center[3], float dim[3], float & dL, float & dG)
	{
		dG = (m[index] + 0.5f) * dim[index] - center[index], dL = dim[index] - dG;
	}

	/// @brief Constructs a Data object
	/// @param dx Extent of space cell in x-direction
	/// @param dy Extent of space cell in y-direction
	/// @param dz Extent of space cell in z-direction
	Data::Data (float dx, float dy, float dz)
	{
		if (dx <= 0.0f) throw "Non-positive dx";
		if (dy <= 0.0f) throw "Non-positive dy";
		if (dz <= 0.0f) throw "Non-positive dz";

		mD[eTX] = dx;
		mD[eTY] = dy;
		mD[eTZ] = dz;
	}

	/// @brief Gets the voxel data's begin forward iterator
	/// @return Forward iterator
	ColumnIterF Data::begin (void)
	{
		return ColumnIterF(EdgeC(false, false), this);
	}

	/// @brief Gets the voxel data's end forward iterator
	/// @return Forward iterator
	ColumnIterF Data::end (void)
	{
		return ColumnIterF(EdgeC(true, false), this);
	}

	/// @brief Gets the voxel data's begin reverse iterator
	/// @return Reverse iterator
	ColumnIterR Data::rbegin (void)
	{
		return ColumnIterR(EdgeC(false, true), this);
	}

	/// @brief Gets the voxel data's end reverse iterator
	/// @return Reverse iterator
	ColumnIterR Data::rend (void)
	{
		return ColumnIterR(EdgeC(true, true), this);
	}

	/// @brief Destructs a Iter object
	Iter::~Iter (void)
	{
		delete mSI;
	}

	/// @brief Compares two iterators for equality
	/// @param v Iterator to compare
	/// @return Equality boolean
	bool Iter::operator == (Iter const & v)
	{
		return *mSI == *v.mSI;
	}

	/// @brief Compares two iterators for inequality
	/// @param v Iterator to compare
	/// @return Inequality boolean
	bool Iter::operator != (Iter const & v)
	{
		return !(*mSI == *v.mSI);
	}
}
--]]

--[[
--
--
-- Sphere.h
--
--
#ifndef VOXEL_SPHERE_H
#define VOXEL_SPHERE_H

#include "Voxel.h"
#include "VoxelImp.h"
#include <list>

namespace Voxel
{
	/// @brief Sphere entry
	struct Entry {
		int mX1;///< x-cell of span start
		int mX2;///< x-cell of span end
		int mZ;	///< z-cell of span
	};

	typedef std::list<Entry> EntryList;

	/// @brief Sphere data
	struct Sphere : public Data {
		// Members
		std::vector<EntryList> mColumn;	///< Column of span lists
		Cell mCenter;	///< Center cell values
		Cell mMin;	///< Minimum cell values
		Cell mMax;	///< Maximum cell values
		void (EntryList::* mOp)(Entry const &);	///< Operation used to add span to row
		float mXL;	///< Distance of center from lesser x-plane
		float mXG;	///< Distance of center from greater x-plane
		float mYL;	///< Distance of center from y-plane above bottom point
		float mYG;	///< Distance of center from y-plane below top point
		float mZL;	///< Distance of center from lesser z-plane
		float mZG;	///< Distance of center from greater z-plane
		float mR2;	///< Cached squared radius

		// Lifetime
		Sphere (float center[3], float radius, float dx, float dy, float dz, Order order);

		// Methods
		StepInfo * EdgeC (bool bEnd, bool bReverse);
		StepInfo * EdgeR (StepInfo * csi, bool bEnd, bool bReverse);
		StepInfo * EdgeS (StepInfo * rsi, bool bEnd, bool bReverse);

		void AddEntry (int x1, int x2, int y, int z);
		void Extend (TripleIndex index, float & cL, float & cG);
		void StepC (StepInfo * csi, bool bReverse, bool bDec);
		void StepR (StepInfo * rsi, bool bReverse, bool bDec);
		void StepS (StepInfo * ssi, bool bReverse, bool bDec);
		void XYSemicircle (float z, int dZ, int count);
		void ZCircle (float yL, float yG, float z, int cyL, int cyG, int cZ);
		void ZSemicircle (float y, float res, int cY, int dY, int cZ);
	};
}

#endif // VOXEL_SPHERE_H
--]]

--[[
--
--
-- Sphere.cpp
--
--
#include "Sphere.h"

namespace Voxel
{
	/// @brief Column step information
	struct CStepInfo : StepInfo {
		// Members
		int mY;	///< Column cell

		/// @brief Compares column step information for equality
		/// @param si Column step information to compare
		/// @return Equality boolean
		bool operator == (StepInfo & si)
		{
			return mY == static_cast<CStepInfo&>(si).mY;
		}

		/// @brief Copies column step information
		/// @return Duplicate
		CStepInfo * Copy (void)
		{
			CStepInfo * csi = new CStepInfo;

			*csi = *this;

			return csi;
		}

		/// @brief Gets the column cell
		/// @return Cell
		int M1 (void)
		{
			return mY;
		}
	};

	/// @brief Row step information
	struct RStepInfo : StepInfo {
		// Members
		EntryList::iterator mFI;///< Forward entry list iterator
		EntryList::reverse_iterator mRI;///< Reverse entry list iterator
		bool mReverse;	///< If true, use reverse iterator

		/// @brief Compares row step information for equality
		/// @param si Row step information to compare
		/// @return Equality boolean
		bool operator == (StepInfo & si)
		{
			RStepInfo & csi = static_cast<RStepInfo&>(si);

			if (mReverse != csi.mReverse) return false;

			return mReverse ? (mRI == csi.mRI) : (mFI == csi.mFI);
		}

		/// @brief Copies row step information
		/// @return Duplicate
		RStepInfo * Copy (void)
		{
			RStepInfo * rsi = new RStepInfo;

			*rsi = *this;

			return rsi;
		}

		/// @brief Gets the span for this entry
		/// @param x1 [out] Initial span cell
		/// @param x2 [out] Final span cell
		void XSpan (int & x1, int & x2)
		{
			x1 = mFI->mX1;
			x2 = mFI->mX2;
		}

		/// @brief Gets the row cell
		/// @return Cell
		int M1 (void)
		{
			return mReverse ? mRI->mZ : mFI->mZ;
		}
	};

	/// @brief Span step information
	struct SStepInfo : StepInfo {
		// Members
		int mI;	///< Initial span cell
		int mF;	///< Final span cell
		bool mEnd;	///< If true, span iterator is at end

		/// @brief Compares span step information for equality
		/// @param si Span step information to compare
		/// @return Equality boolean
		bool operator == (StepInfo & si)
		{
			return mEnd == static_cast<SStepInfo&>(si).mEnd;
		}

		/// @brief Copies span step information
		/// @return Duplicate
		SStepInfo * Copy (void)
		{
			SStepInfo * ssi = new SStepInfo;

			*ssi = *this;

			return ssi;
		}

		/// @brief Gets the initial span cell
		/// @return Cell
		int M1 (void)
		{
			return mI;
		}

		/// @brief Gets the final span cell
		/// @return Cell
		int M2 (void)
		{
			return mF;
		}
	};

	const int eXY = 0x1;///< Swap x, y
	const int eXZ = 0x2;///< Swap x, z
	const int eYZ = 0x4;///< Swap y, z

	/// @brief Constructs a RenderData object
	/// @param center Sphere center, relative to space origin
	/// @param radius Sphere radius
	/// @param dx Extent of space cell in x-direction
	/// @param dy Extent of space cell in y-direction
	/// @param dz Extent of space cell in z-direction
	/// @param order Order used to obtain spans
	Sphere::Sphere (float center[3], float radius, float dx, float dy, float dz, Order order) : Data(dx, dy, dz),
																								mCenter(center, dx, dy, dz, 0.0f),
																								mMin(center, dx, dy, dz, -radius),
																								mMax(center, dx, dy, dz, +radius),
																								mOp(&EntryList::push_back),
																								mR2(radius * radius)
	{
		if (radius <= 0.0f) throw "Non-positive radius";

		// Convert the displacements from the given volume ordering to the standard form.
		int flags[] = { eXY | eYZ, eXZ, eYZ, 0, eXZ | eYZ, eXY };

		if (flags[order] & eXY) std::swap(mD[eTX], mD[eTY]), std::swap(center[eTX], center[eTY]);
		if (flags[order] & eXZ) std::swap(mD[eTX], mD[eTZ]), std::swap(center[eTX], center[eTZ]);
		if (flags[order] & eYZ) std::swap(mD[eTY], mD[eTZ]), std::swap(center[eTY], center[eTZ]);

		/// Install the column. Insert the known entry through the center.
		mColumn.resize(mMax.m[eTY] - mMin.m[eTY] + 1);

		AddEntry(mMin.m[eTX], mMax.m[eTX], mCenter.m[eTY], mCenter.m[eTZ]);

		// Get the distances from the center to each of the cell edges in its xz-plane.
		mCenter.Distances(eTX, center, mD, mXL, mXG);
		mCenter.Distances(eTZ, center, mD, mZL, mZG);

		// Get the distances from the center to the xz-planes that form the ceiling and
		// floor of the cells of the bottom and top points, respectively.
		mCenter.Distances(eTY, center, mD, mYL, mYG);

		Extend(eTY, mYL, mYG);

		// Do the z = z0 circle.
		ZCircle(mYL, mYG, 0.0f, mMin.m[eTY], mMax.m[eTY], mCenter.m[eTZ]);

		// Do the x = x0 and y = y0 circles.
		XYSemicircle(mZL, -1, mCenter.m[eTZ] - mMin.m[eTZ]);
		mOp = &EntryList::push_front;
		XYSemicircle(mZG, +1, mMax.m[eTZ] - mCenter.m[eTZ]);
	}

	/// @brief Gets an edge column iterator
	/// @param bEnd If true, get the end iterator
	/// @param bReverse If true, get reverse info
	/// @return New column step info
	StepInfo * Sphere::EdgeC (bool bEnd, bool bReverse)
	{
		CStepInfo * csi = new CStepInfo;

		if (bReverse) csi->mY = bEnd ? mMin.m[eTY] - 1 : mMax.m[eTY];

		else csi->mY = bEnd ? mMax.m[eTY] + 1 : mMin.m[eTY];

		return csi;
	}

	/// @brief Gets an edge row iterator
	/// @param csi Column step info
	/// @param bEnd If true, get the end iterator
	/// @param bReverse If true, get reverse info
	/// @return New row step info
	StepInfo * Sphere::EdgeR (StepInfo * csi, bool bEnd, bool bReverse)
	{
		EntryList & el = mColumn[static_cast<CStepInfo*>(csi)->mY - mMin.m[eTY]];

		RStepInfo * rsi = new RStepInfo;

		if (bReverse) rsi->mRI = bEnd ? el.rend() : el.rbegin();

		else rsi->mFI = bEnd ? el.end() : el.begin();
		
		rsi->mReverse = bReverse;

		return rsi;
	}

	/// @brief Gets an edge span iterator
	/// @param rsi Row step info
	/// @param bEnd If true, get the end iterator
	/// @param bReverse If true, get reverse info
	/// @return New span step info
	StepInfo * Sphere::EdgeS (StepInfo * rsi, bool bEnd, bool bReverse)
	{
		SStepInfo * ssi = new SStepInfo;

		if (bEnd) ssi->mEnd = true;

		else
		{
			ssi->mEnd = false;

			static_cast<RStepInfo*>(rsi)->XSpan(ssi->mI, ssi->mF);

			if (bReverse) std::swap(ssi->mI, ssi->mF);
		}

		return ssi;
	}

	/// @brief Adds an entry to the row
	/// @param x1 x-cell of span start
	/// @param x2 x-cell of span end
	/// @param y y-cell of row
	/// @param z z-cell of span
	void Sphere::AddEntry (int x1, int x2, int y, int z)
	{
		Entry entry;

		entry.mX1 = x1;
		entry.mX2 = x2;
		entry.mZ = z;

		(mColumn[y - mMin.m[eTY]].*mOp)(entry);
	}

	/// @brief Extends a distance to just short of the extrema cells
	/// @param index Coordinate index
	/// @param cL [out] Lesser coordinate to extend
	/// @param cG [out] Greater coordinate to extend
	void Sphere::Extend (TripleIndex index, float & cL, float & cG)
	{
		int dL = mCenter.m[index] - mMin.m[index] - 1;	if (dL > 0) cL += dL * mD[index];
		int dG = mMax.m[index] - mCenter.m[index] - 1;	if (dG > 0) cG += dG * mD[index];
	}

	/// @brief Steps along a column
	/// @param csi Column step info
	/// @param bReverse If true, step in reverse
	/// @param bDec If true, decrement
	void Sphere::StepC (StepInfo * csi, bool bReverse, bool bDec)
	{
		int dY = bDec ? -1 : +1;

		static_cast<CStepInfo*>(csi)->mY += bReverse ? -dY : +dY;
	}

	/// @brief Steps along a row
	/// @param rsi Row step info
	/// @param bReverse If true, step in reverse
	/// @param bDec If true, decrement
	void Sphere::StepR (StepInfo * rsi, bool bReverse, bool bDec)
	{
		RStepInfo * pRSI = static_cast<RStepInfo*>(rsi);

		if (bReverse) bDec ? --pRSI->mRI : ++pRSI->mRI;

		else bDec ? --pRSI->mFI : ++pRSI->mFI;
	}

	/// @brief Steps along a span
	/// @param ssi Span step info
	/// @param bReverse If true, step in reverse
	/// @param bDec If true, decrement
	void Sphere::StepS (StepInfo * ssi, bool bReverse, bool bDec)
	{
		static_cast<SStepInfo*>(ssi)->mEnd = true;
	}

	/// @brief Renders semicircles of x = x0, y = y0 and all their z-circles
	/// @param z z-value of start of x = x0 semicircle
	/// @param dZ z-cell increment
	/// @param count Count of z-cells to cover
	void Sphere::XYSemicircle (float z, int dZ, int count)
	{
		int cx1 = mMin.m[eTX], cx2 = mMax.m[eTX];
		int cy1 = mMin.m[eTY], cy2 = mMax.m[eTY];
		int cZ = mCenter.m[eTZ];

		float xL = mXL, xG = mXG;
		float yL = mYL, yG = mYG;

		Extend(eTX, xL, xG);

		for (int index = 0; index < count; ++index, z += mD[eTZ])
		{
			cZ += dZ;

			float resZ = mR2 - z * z;

			// Iterate inward along the yz-plane until r� - y� - z� >= 0. Until then,
			// the corner is poking out of the x0 semicircle. Render the semicircle.
			while (yL > mD[eTY] && yL * yL > resZ) yL -= mD[eTY], ++cy1;
			while (yG > mD[eTY] && yG * yG > resZ) yG -= mD[eTY], --cy2;

			ZCircle(yL, yG, z, cy1, cy2, cZ);

			// Iterate inward along the xz-plane until r� - x� - z� < 0. Until then,
			// the corner is poking out of the y0 semicircle. Install this entry.
			while (xL > mD[eTX] && xL * xL > resZ) xL -= mD[eTX], ++cx1;
			while (xG > mD[eTX] && xG * xG > resZ) xG -= mD[eTX], --cx2;

			AddEntry(cx1, cx2, mCenter.m[eTY], cZ);
		}
	}

	/// @brief Renders the circle at a given z
	/// @param fYL Lesser y-value
	/// @param fYG Greater y-value
	/// @param z z-value at which to render
	/// @param cyL Lesser y-cell
	/// @param cyG Greater y-cell
	/// @param cZ z-cell
	void Sphere::ZCircle (float yL, float yG, float z, int cyL, int cyG, int cZ)
	{
		float res = mR2 - z * z;

		ZSemicircle(yL, res, cyL, +1, cZ);
		ZSemicircle(yG, res, cyG, -1, cZ);
	}

	/// @brief Renders a semicircle for a given z
	/// @param y y-value of start of semicircle
	/// @param res Residue term, r� - z�
	/// @param cY y-cell of start of semicircle
	/// @param dY y-cell increment
	/// @param cZ z-cell
	void Sphere::ZSemicircle (float y, float res, int cY, int dY, int cZ)
	{
		int cx1 = mCenter.m[eTX], cx2 = mCenter.m[eTX];

		for (float xL = mXL, xG = mXG; cY != mCenter.m[eTY]; y -= mD[eTY], cY += dY)
		{
			float resY = res - y * y;

			// Iterate along the z semicircle until r� - x� - y� - z� < 0. Then, the
			// corner is poking out of the z semicircle. Install this entry.
			while (xL * xL <= resY) xL += mD[eTX], --cx1;
			while (xG * xG <= resY) xG += mD[eTX], ++cx2;

			AddEntry(cx1, cx2, cY, cZ);
		}
	}
}
--]]

--[[
--
--
-- ColumnIter.cpp
--
--
#include "Voxel.h"
#include "VoxelImp.h"

namespace Voxel
{
	/// @brief Derefernces the column iterator
	/// @return Column cell
	int ColumnIter::operator * (void)
	{
		return mSI->M1();
	}

	/// @brief Gets the column's begin forward iterator
	/// @return Forward iterator
	RowIterF ColumnIter::begin (void)
	{
		return RowIterF(mVD->EdgeR(mSI, false, false), mVD);
	}

	/// @brief Gets the column's end forward iterator
	/// @return Forward iterator
	RowIterF ColumnIter::end (void)
	{
		return RowIterF(mVD->EdgeR(mSI, true, false), mVD);
	}

	/// @brief Gets the column's begin reverse iterator
	/// @return Reverse iterator
	RowIterR ColumnIter::rbegin (void)
	{
		return RowIterR(mVD->EdgeR(mSI, false, true), mVD);
	}

	/// @brief Gets the column's end reverse iterator
	/// @return Reverse iterator
	RowIterR ColumnIter::rend (void)
	{
		return RowIterR(mVD->EdgeR(mSI, true, true), mVD);
	}

	/// @brief Copy constructs a ColumnIterF object
	/// @param vo ColumnIterF object from which to copy
	ColumnIterF::ColumnIterF (ColumnIterF const & vo) : ColumnIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the forward column iterator
	void ColumnIterF::operator ++ (void)
	{
		mVD->StepC(mSI, false, false);
	}

	/// @brief Decrements the forward column iterator
	void ColumnIterF::operator -- (void)
	{
		mVD->StepC(mSI, false, true);
	}

	/// @brief Copy constructs a ColumnIterR object
	/// @param vo ColumnIterR object from which to copy
	ColumnIterR::ColumnIterR (ColumnIterR const & vo) : ColumnIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the reverse column iterator
	void ColumnIterR::operator ++ (void)
	{
		mVD->StepC(mSI, true, false);
	}

	/// @brief Decrements the reverse column iterator
	void ColumnIterR::operator -- (void)
	{
		mVD->StepC(mSI, true, true);
	}
}
--]]

--[[
--
--
-- RowIter.cpp
--
--
#include "Voxel.h"
#include "VoxelImp.h"

namespace Voxel
{
	/// @brief Dereferences the row iterator
	/// @return Row cell
	int RowIter::operator * (void)
	{
		 return mSI->M1();
	}

	/// @brief Gets the row's begin forward iterator
	/// @return Forward iterator
	SpanIterF RowIter::begin (void)
	{
		return SpanIterF(mVD->EdgeS(mSI, false, false), mVD);
	}

	/// @brief Gets the row's end forward iterator
	/// @return Forward iterator
	SpanIterF RowIter::end (void)
	{
		return SpanIterF(mVD->EdgeS(mSI, true, false), mVD);
	}

	/// @brief Gets the row's begin reverse iterator
	/// @return Reverse iterator
	SpanIterR RowIter::rbegin (void)
	{
		return SpanIterR(mVD->EdgeS(mSI, false, true), mVD);
	}

	/// @brief Gets the row's end reverse iterator
	/// @return Reverse iterator
	SpanIterR RowIter::rend (void)
	{
		return SpanIterR(mVD->EdgeS(mSI, true, true), mVD);
	}

	/// @brief Copy constructs a RowIterF object
	/// @param vo RowIterF object from which to copy
	RowIterF::RowIterF (RowIterF const & vo) : RowIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the forward row iterator
	void RowIterF::operator ++ (void)
	{
		mVD->StepR(mSI, false, false);
	}

	/// @brief Decrements the forward row iterator
	void RowIterF::operator -- (void)
	{
		mVD->StepR(mSI, false, true);
	}

	/// @brief Copy constructs a RowIterR object
	/// @param vo RowIterR object from which to copy
	RowIterR::RowIterR (RowIterR const & vo) : RowIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the reverse row iterator
	void RowIterR::operator ++ (void)
	{
		mVD->StepR(mSI, true, false);
	}

	/// @brief Decrements the reverse row iterator
	void RowIterR::operator -- (void)
	{
		mVD->StepR(mSI, true, true);
	}
}
--]]

--[[
--
--
-- SpanIter.h
--
--
#include "Voxel.h"
#include "VoxelImp.h"

namespace Voxel
{
	/// @brief Gets the initial element of the span
	/// @return Initial cell
	int SpanIter::I (void)
	{
		return mSI->M1();
	}

	/// @brief Gets the final element of the span
	/// @return Final cell
	int SpanIter::F (void)
	{
		return mSI->M2();
	}

	/// @brief Copy constructs a SpanIterF object
	/// @param vo SpanIterF object from which to copy
	SpanIterF::SpanIterF (SpanIterF const & vo) : SpanIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the forward span iterator
	void SpanIterF::operator ++ (void)
	{
		mVD->StepS(mSI, false, false);
	}

	/// @brief Decrements the forward span iterator
	void SpanIterF::operator -- (void)
	{
		mVD->StepS(mSI, false, true);
	}

	/// @brief Copy constructs a SpanIterR object
	/// @param vo SpanIterR object from which to copy
	SpanIterR::SpanIterR (SpanIterR const & vo) : SpanIter(vo.mSI->Copy(), vo.mVD)
	{
	}

	/// @brief Increments the reverse span iterator
	void SpanIterR::operator ++ (void)
	{
		mVD->StepS(mSI, true, false);
	}

	/// @brief Decrements the reverse span iterator
	void SpanIterR::operator -- (void)
	{
		mVD->StepS(mSI, true, true);
	}
}
--]]